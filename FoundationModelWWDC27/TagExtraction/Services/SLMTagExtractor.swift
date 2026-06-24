import Foundation
import os

public struct SLMTagExtractor: TagExtracting, TagExtractionAvailabilityProviding, Sendable {
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "SLMTagExtractor")

    private let modelClient: OnDeviceLanguageModelClient
    private let fallback: TagExtracting
    private let normalizer: TagNormalizer

    public init(
        modelClient: OnDeviceLanguageModelClient,
        fallback: TagExtracting,
        normalizer: TagNormalizer = TagNormalizer()
    ) {
        self.modelClient = modelClient
        self.fallback = fallback
        self.normalizer = normalizer
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
                let generated = try await modelClient.generateTagCandidates(for: trimmed)
                Self.logger.debug("Model returned \(generated.count) tag candidates")

                let tags = normalizer.normalize(generated.map(\.value), config: request.config)

                guard !tags.isEmpty else {
                    Self.logger.warning("Normalizer removed all model candidates; falling back")
                    return try await fallback.extractTags(from: request)
                }

                Self.logger.debug("Returning \(tags.count) normalized on-device tags")

                return TagExtractionResult(tags: tags, source: .onDeviceModel)
            } catch {
                Self.logger.error("Model extraction failed with error: \(error.localizedDescription, privacy: .public); falling back")
                return try await fallback.extractTags(from: request)
            }
        case .unavailable(let reason):
            Self.logger.notice("Model unavailable: \(reason, privacy: .public); using fallback")
            return try await fallback.extractTags(from: request)
        }
    }
}