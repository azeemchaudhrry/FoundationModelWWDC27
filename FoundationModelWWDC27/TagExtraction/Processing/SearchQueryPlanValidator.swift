import Foundation

public struct SearchQueryPlanValidator: Sendable {
    public let invalidGeneratedTerms: Set<String> = [
        "query",
        "product search",
        "shopper query",
        "attribute",
        "attributes",
        "expansion",
        "expanded",
        "warn",
        "warning",
        "warnings",
        "product specification",
        "event planning",
        "color",
        "size",
        "material",
        "fit",
        "style",
        "activity",
        "occasion",
        "weather",
        "age group",
        "feature",
        "uncertainty"
    ]

    private let contextOnlyProductTypes: Set<String> = [
        "wedding",
        "party",
        "cocktail",
        "cocktail party",
        "travel",
        "winter travel",
        "weather",
        "hot weather",
        "tropical weather",
        "commuting",
        "college",
        "activity",
        "occasion"
    ]

    private let knownProductTypes: Set<String> = [
        "shirt",
        "linen shirt",
        "dress",
        "sneakers",
        "backpack",
        "jacket",
        "swimsuit",
        "swimwear",
        "formal shoes",
        "gym shorts",
        "running shorts",
        "hoodie",
        "crossbody bag",
        "school uniform",
        "socks"
    ]

    private let safeTypeAliases: [String: Set<String>] = [
        "swimsuit": ["swimwear"],
        "gym shorts": ["running shorts"]
    ]

    public init() {}

    public func containsInvalidGeneratedTerm(_ query: String) -> Bool {
        let normalized = normalizedForMatching(query)

        return invalidGeneratedTerms.contains { term in
            containsWholeTerm(normalized, term: normalizedForTerm(term))
        }
    }

    public func validateOrFallback(
        plan: ProductSearchQueryPlan,
        originalQuery: String,
        fallbackExtractor: RuleBasedCatalogueQueryExtractor = RuleBasedCatalogueQueryExtractor()
    ) -> ProductSearchQueryPlan {
        let sanitized = ProductSearchQueryPlan(
            productType: plan.productType.trimmingCharacters(in: .whitespacesAndNewlines),
            primaryQuery: plan.primaryQuery.trimmingCharacters(in: .whitespacesAndNewlines),
            fallbackQuery: plan.fallbackQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        guard isValid(sanitized, originalQuery: originalQuery) else {
            return fallbackExtractor.extract(from: originalQuery)
        }

        return sanitized
    }

    public func makeCatalogueSearchURL(query: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.next.co.uk"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "w", value: query)
        ]
        return components.url
    }

    private func isValid(_ plan: ProductSearchQueryPlan, originalQuery: String) -> Bool {
        let productType = normalizedForTerm(plan.productType)
        guard !productType.isEmpty else {
            return false
        }

        let primaryQuery = plan.primaryQuery
        let fallbackQuery = plan.fallbackQuery
        guard !primaryQuery.isEmpty, !fallbackQuery.isEmpty else {
            return false
        }

        if containsInvalidGeneratedTerm(primaryQuery) || containsInvalidGeneratedTerm(fallbackQuery) {
            return false
        }

        if contextOnlyProductTypes.contains(productType) {
            return false
        }

        if !containsProductTypeOrSafeVariant(in: primaryQuery, productType: productType) {
            return false
        }

        if !containsProductTypeOrSafeVariant(in: fallbackQuery, productType: productType) {
            return false
        }

        let generatedCombined = "\(primaryQuery) \(fallbackQuery)"
        if introducesUnrequestedProductType(
            originalQuery: originalQuery,
            generatedQueries: generatedCombined,
            productType: productType
        ) {
            return false
        }

        return true
    }

    private func containsProductTypeOrSafeVariant(in query: String, productType: String) -> Bool {
        let normalizedQuery = normalizedForMatching(query)
        let variants = productTypeVariants(for: productType)
        for variant in variants {
            if containsWholeTerm(normalizedQuery, term: normalizedForTerm(variant)) {
                return true
            }
        }

        if let aliases = safeTypeAliases[productType] {
            for alias in aliases {
                if containsWholeTerm(normalizedQuery, term: normalizedForTerm(alias)) {
                    return true
                }
            }
        }

        return false
    }

    private func introducesUnrequestedProductType(
        originalQuery: String,
        generatedQueries: String,
        productType: String
    ) -> Bool {
        let normalizedOriginal = normalizedForMatching(originalQuery)
        let normalizedGenerated = normalizedForMatching(generatedQueries)

        for candidate in knownProductTypes where normalizedForTerm(candidate) != productType {
            let normalizedCandidate = normalizedForTerm(candidate)
            guard !normalizedCandidate.isEmpty else {
                continue
            }

            let appearsInGenerated = containsWholeTerm(normalizedGenerated, term: normalizedCandidate)
            let appearsInOriginal = containsWholeTerm(normalizedOriginal, term: normalizedCandidate)

            if appearsInGenerated && !appearsInOriginal {
                return true
            }
        }

        return false
    }

    private func productTypeVariants(for productType: String) -> Set<String> {
        let normalized = normalizedForTerm(productType)
        guard !normalized.isEmpty else {
            return []
        }

        var variants: Set<String> = [normalized]
        let parts = normalized.split(separator: " ").map(String.init)
        guard let last = parts.last else {
            return variants
        }

        let singular = singularized(last)
        let plural = pluralized(last)

        if !singular.isEmpty {
            variants.insert(replacingLastWord(in: parts, with: singular))
        }
        if !plural.isEmpty {
            variants.insert(replacingLastWord(in: parts, with: plural))
        }

        return variants
    }

    private func singularized(_ word: String) -> String {
        if word.hasSuffix("ies") && word.count > 3 {
            return String(word.dropLast(3)) + "y"
        }
        if word.hasSuffix("es") && word.count > 2 {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("s") && word.count > 1 {
            return String(word.dropLast())
        }
        return word
    }

    private func pluralized(_ word: String) -> String {
        if word.hasSuffix("y") && word.count > 1 {
            return String(word.dropLast()) + "ies"
        }
        if word.hasSuffix("s") {
            return word
        }
        return word + "s"
    }

    private func replacingLastWord(in parts: [String], with replacement: String) -> String {
        guard !parts.isEmpty else {
            return replacement
        }
        var updated = parts
        updated[updated.count - 1] = replacement
        return updated.joined(separator: " ")
    }

    private func normalizedForMatching(_ text: String) -> String {
        let lowercased = text.lowercased()
        let replaced = lowercased.replacingOccurrences(
            of: #"[^a-z0-9]+"#,
            with: " ",
            options: .regularExpression
        )
        let collapsed = replaced.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return " \(collapsed.trimmingCharacters(in: .whitespacesAndNewlines)) "
    }

    private func normalizedForTerm(_ term: String) -> String {
        normalizedForMatching(term).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsWholeTerm(_ normalizedText: String, term: String) -> Bool {
        guard !term.isEmpty else {
            return false
        }
        return normalizedText.contains(" \(term) ")
    }
}