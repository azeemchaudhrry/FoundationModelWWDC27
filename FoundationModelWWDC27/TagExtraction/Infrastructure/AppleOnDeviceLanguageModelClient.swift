import Foundation
import os
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
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "AppleModelClient")

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

    public func generateTagCandidates(for query: String) async throws -> [OnDeviceModelTagCandidate] {
#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            Self.logger.debug("Starting on-device tag generation")
            let session = LanguageModelSession(
                model: SystemLanguageModel(useCase: .contentTagging, guardrails: .default),
                instructions: instructions
            )
            session.prewarm()

            let options = GenerationOptions(temperature: 0.2)
            let response = try await session.respond(
                to: query,
                generating: GeneratedTagList.self,
                options: options
            )

            let mapped = response.content.tags.map {
                OnDeviceModelTagCandidate(value: $0.value, confidence: nil)
            }

            Self.logger.debug("On-device generation completed with \(mapped.count) candidates")
            return mapped
        }
        Self.logger.error("Tag generation failed: platform_version_unsupported")
        throw TagExtractionError.modelUnavailable("platform_version_unsupported")
#else
        Self.logger.error("Tag generation failed: foundation_models_unavailable")
        throw TagExtractionError.modelUnavailable("foundation_models_unavailable")
#endif
    }
}
