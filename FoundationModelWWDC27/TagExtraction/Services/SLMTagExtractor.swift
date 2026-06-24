import Foundation

public struct SLMTagExtractor: TagExtracting, Sendable {
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

    public func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        let trimmed = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TagExtractionError.invalidInput
        }

        switch modelClient.availability() {
        case .available:
            do {
                let generated = try await modelClient.generateTagCandidates(for: trimmed)
#if DEBUG
                print("[SLMTagExtractor] raw model candidates:", generated.map(\.value))
#endif
                let tags = normalizer.normalize(generated.map(\.value), config: request.config)

                guard !tags.isEmpty else {
#if DEBUG
                    print("[SLMTagExtractor] normalizer emptied all candidates → fallback")
#endif
                    return try await fallback.extractTags(from: request)
                }

                return TagExtractionResult(tags: tags, source: .onDeviceModel)
            } catch {
#if DEBUG
                print("[SLMTagExtractor] generation failed → fallback:", error)
#endif
                return try await fallback.extractTags(from: request)
            }
        case .unavailable:
            return try await fallback.extractTags(from: request)
        }
    }
}