import Foundation
import os

public struct SLMTagExtractor: TagExtracting, TagExtractionAvailabilityProviding, Sendable {
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "SLMTagExtractor")

    private let modelClient: OnDeviceLanguageModelClient
    private let fallback: TagExtracting
    private let normalizer: TagNormalizer
    private let searchPlanValidator: SearchQueryPlanValidator
    private let ruleBasedExtractor: RuleBasedCatalogueQueryExtractor

    public init(
        modelClient: OnDeviceLanguageModelClient,
        fallback: TagExtracting,
        normalizer: TagNormalizer = TagNormalizer(),
        searchPlanValidator: SearchQueryPlanValidator = SearchQueryPlanValidator(),
        ruleBasedExtractor: RuleBasedCatalogueQueryExtractor = RuleBasedCatalogueQueryExtractor()
    ) {
        self.modelClient = modelClient
        self.fallback = fallback
        self.normalizer = normalizer
        self.searchPlanValidator = searchPlanValidator
        self.ruleBasedExtractor = ruleBasedExtractor
    }

    public func modelAvailability() -> TagExtractionModelAvailability {
        switch modelClient.availability() {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason)
        }
    }

    public func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        let trimmed = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Self.logger.error("Rejected extraction due to empty input")
            throw TagExtractionError.invalidInput
        }

        switch modelClient.availability() {
        case .available:
            Self.logger.debug("On-device model is available; attempting model extraction")
            do {
                let queryRequest = ProductSearchQueryRequest(originalQuery: request.text, config: request.config)
                let generatedPlan = try await modelClient.generateSearchQueryPlan(for: queryRequest)
                let plan = searchPlanValidator.validateOrFallback(
                    plan: generatedPlan,
                    originalQuery: request.text,
                    fallbackExtractor: ruleBasedExtractor
                )
                Self.logger.notice("Validated plan query=\"\(request.text, privacy: .public)\" productType=\(plan.productType, privacy: .public) primary=\(plan.primaryQuery, privacy: .public) fallback=\(plan.fallbackQuery, privacy: .public)")

                let query = plan.primaryQuery
                if let primaryURL = searchPlanValidator.makeCatalogueSearchURL(query: query) {
                    Self.logger.debug("Primary catalog query URL: \(primaryURL.absoluteString, privacy: .public)")
                }

                let primaryTags = tagsFromQuery(
                    query,
                    productType: plan.productType,
                    config: request.config
                )

                if !isWeak(query: query, productType: plan.productType, tags: primaryTags) {
                    Self.logger.debug("Returning \(primaryTags.count) normalized tags from primary query")
                    return TagExtractionResult(tags: primaryTags, source: .onDeviceModel)
                }

                Self.logger.notice("Primary query produced weak or empty tags; using fallback query")
                let fallbackQuery = plan.fallbackQuery
                if let fallbackURL = searchPlanValidator.makeCatalogueSearchURL(query: fallbackQuery) {
                    Self.logger.debug("Fallback catalog query URL: \(fallbackURL.absoluteString, privacy: .public)")
                }

                let fallbackTags = tagsFromQuery(
                    fallbackQuery,
                    productType: plan.productType,
                    config: request.config
                )

                guard !isWeak(query: fallbackQuery, productType: plan.productType, tags: fallbackTags) else {
                    Self.logger.warning("Fallback query also produced empty tags; falling back to keyword extractor")
                    return try await fallback.extractTags(from: request)
                }

                Self.logger.debug("Returning \(fallbackTags.count) normalized tags from fallback query")
                return TagExtractionResult(tags: fallbackTags, source: .onDeviceModel)
            } catch {
                Self.logger.error("Model extraction failed with error: \(error.localizedDescription, privacy: .public); falling back")
                return try await fallback.extractTags(from: request)
            }
        case .unavailable(let reason):
            Self.logger.notice("Model unavailable: \(reason, privacy: .public); using fallback")
            return try await fallback.extractTags(from: request)
        }
    }

    private func tagsFromQuery(
        _ query: String,
        productType: String,
        config: TagExtractionConfig
    ) -> [Tag] {
        let productTypeWords = Set(
            productType
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )

        let attributeTokens = Self.extractAttributeTokens(from: query.lowercased(), minimumLength: config.minimumTagLength)
            .filter { !productTypeWords.contains($0) }

        var candidates: [String] = [productType]
        candidates.append(contentsOf: attributeTokens)

        return normalizer.normalize(candidates, config: config)
    }

    private static func extractAttributeTokens(from query: String, minimumLength: Int) -> [String] {
        let pattern = #"\d{1,2}\s*(?:years?|yrs?|months?)|[a-z0-9]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return query.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        }

        let nsRange = NSRange(query.startIndex..<query.endIndex, in: query)
        return regex.matches(in: query, range: nsRange).compactMap { match -> String? in
            guard let range = Range(match.range, in: query) else { return nil }
            let token = String(query[range])
            return token.count >= minimumLength ? token : nil
        }
    }

    private func isWeak(query: String, productType: String, tags: [Tag]) -> Bool {
        guard !tags.isEmpty else {
            return true
        }

        let queryTokenCount = query
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .count

        let productTypeTokenCount = productType
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .count

        return queryTokenCount <= productTypeTokenCount
    }
}