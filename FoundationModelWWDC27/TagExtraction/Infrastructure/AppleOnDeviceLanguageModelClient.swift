import Foundation
import os
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
private struct GeneratedCatalogueSearchQuery {
    @Guide(description: "The exact product item the shopper wants to buy.")
    var productType: String

    @Guide(description: "The best concise ecommerce catalogue search query.")
    var primaryQuery: String

    @Guide(description: "A broader backup ecommerce catalogue query that still preserves product type.")
    var fallbackQuery: String
}
#endif

public struct AppleOnDeviceLanguageModelClient: OnDeviceLanguageModelClient, Sendable {
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "AppleModelClient")

    private let instructions: String
    private let promptBuilder: TagPromptBuilder

    public init(promptBuilder: TagPromptBuilder = TagPromptBuilder()) {
        self.instructions = """
        You create ecommerce catalogue search queries from a shopper sentence.

        Return only the requested structured output.

        Definitions:
        - productType = the item the shopper wants to buy.
        - primaryQuery = the best short search query.
        - fallbackQuery = a broader search query if primaryQuery returns poor results.

        Rules:
        - productType must be a real product noun from the shopper query.
        - primaryQuery and fallbackQuery must contain the productType.
        - Keep explicit color, material, size, fit, and feature words.
        - Keep the shopper's age or age group when mentioned (e.g. "6 years", "toddler", "kids", "adult") — this is critical shopper context for finding the right product, never drop it.
        - Remove filler words like "I want", "I need", "show me", "find me", and "looking for".
        - Remove timing words like "this weekend".
        - Do not use generic words: query, product search, shopper query, attribute, expansion, warning, color, size, material, style, feature.
        - Do not invent a product type.
        - Do not use the occasion or activity as the product type.

        Examples:

        Input: I need a black dress for a cocktail party this weekend.
        productType: dress
        primaryQuery: black cocktail dress
        fallbackQuery: black dress

        Input: I need formal shoes for a wedding, preferably brown leather.
        productType: formal shoes
        primaryQuery: brown leather formal shoes
        fallbackQuery: formal shoes

        Input: Looking for a school uniform for my 6 years old in red
        productType: school uniform
        primaryQuery: red school uniform 6 years
        fallbackQuery: kids red school uniform

        Input: I want a soft oversized hoodie for winter travel.
        productType: hoodie
        primaryQuery: soft oversized hoodie
        fallbackQuery: oversized hoodie
        """
        self.promptBuilder = promptBuilder
    }

    public func availability() -> OnDeviceModelAvailability {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                Self.logger.debug("SystemLanguageModel availability: available")
                return .available
            case .unavailable(.deviceNotEligible):
                Self.logger.notice("SystemLanguageModel unavailable: device_not_eligible")
                return .unavailable("device_not_eligible")
            case .unavailable(.appleIntelligenceNotEnabled):
                Self.logger.notice("SystemLanguageModel unavailable: apple_intelligence_not_enabled")
                return .unavailable("apple_intelligence_not_enabled")
            case .unavailable(.modelNotReady):
                Self.logger.notice("SystemLanguageModel unavailable: model_not_ready")
                return .unavailable("model_not_ready")
            case .unavailable(let reason):
                Self.logger.notice("SystemLanguageModel unavailable: \(String(describing: reason), privacy: .public)")
                return .unavailable(String(describing: reason))
            @unknown default:
                Self.logger.notice("SystemLanguageModel unavailable: unknown")
                return .unavailable("unknown")
            }
        } else {
            Self.logger.notice("SystemLanguageModel unavailable: platform_version_unsupported")
            return .unavailable("platform_version_unsupported")
        }
#else
        Self.logger.notice("SystemLanguageModel unavailable: foundation_models_unavailable")
        return .unavailable("foundation_models_unavailable")
#endif
    }

    public func generateSearchQueryPlan(for request: ProductSearchQueryRequest) async throws -> ProductSearchQueryPlan {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Self.logger.debug("Starting on-device search query plan generation")
            let session = LanguageModelSession(
                model: SystemLanguageModel(useCase: .contentTagging, guardrails: .default),
                instructions: instructions
            )

            let prompt = promptBuilder.buildPrompt(for: request)
            let options = GenerationOptions(temperature: 0.2)
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedCatalogueSearchQuery.self,
                options: options
            )

            let generated = response.content
            let mapped = ProductSearchQueryPlan(
                productType: generated.productType,
                primaryQuery: generated.primaryQuery,
                fallbackQuery: generated.fallbackQuery
            )

            Self.logger.notice("Raw model plan query=\"\(request.originalQuery, privacy: .public)\" productType=\(mapped.productType, privacy: .public) primary=\(mapped.primaryQuery, privacy: .public) fallback=\(mapped.fallbackQuery, privacy: .public)")
            return mapped
        }
        Self.logger.error("Search query plan generation failed: platform_version_unsupported")
        throw TagExtractionError.modelUnavailable("platform_version_unsupported")
#else
        Self.logger.error("Search query plan generation failed: foundation_models_unavailable")
        throw TagExtractionError.modelUnavailable("foundation_models_unavailable")
#endif
    }
}
