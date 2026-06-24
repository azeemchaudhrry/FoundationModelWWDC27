import Foundation
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
private struct GeneratedTagList {
    var tags: [GeneratedTagItem]
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable
private struct GeneratedTagItem {
    @Guide(description: "A concise 1-3 word ecommerce search term. Keep multi-word product phrases intact, e.g. 'white sneakers', 'running shoes'. Exclude filler and command words.")
    var value: String
}
#endif

public struct AppleOnDeviceLanguageModelClient: OnDeviceLanguageModelClient, Sendable {

    private let instructions: String

    public init() {
        self.instructions = """
        You extract high-quality ecommerce search tags from a shopper query.
        Focus on product type, color, material, use case, activity, fit, style, \
        weather, occasion, and key attributes. Keep meaningful product phrases \
        together. Return only terms that improve catalog search and filtering. \
        Each tag is 1-3 words.
        """
    }

    public func availability() -> OnDeviceModelAvailability {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable("device_not_eligible")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("apple_intelligence_not_enabled")
            case .unavailable(.modelNotReady):
                return .unavailable("model_not_ready")
            case .unavailable(let reason):
                return .unavailable(String(describing: reason))
            @unknown default:
                return .unavailable("unknown")
            }
        } else {
            return .unavailable("platform_version_unsupported")
        }
#else
        return .unavailable("foundation_models_unavailable")
#endif
    }

    public func generateTagCandidates(for query: String) async throws -> [OnDeviceModelTagCandidate] {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            let session = LanguageModelSession(
                model: SystemLanguageModel.default,
                instructions: instructions
            )
            session.prewarm()

            let options = GenerationOptions(temperature: 0.2)
            let response = try await session.respond(
                to: query,
                generating: GeneratedTagList.self,
                options: options
            )
            return response.content.tags.map {
                OnDeviceModelTagCandidate(value: $0.value, confidence: nil)
            }
        }
        throw TagExtractionError.modelUnavailable("platform_version_unsupported")
#else
        throw TagExtractionError.modelUnavailable("foundation_models_unavailable")
#endif
    }
}