import Foundation
import os

public struct FallbackKeywordExtractor: TagExtracting, Sendable {
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "FallbackExtractor")

    private let normalizer: TagNormalizer

    public init(normalizer: TagNormalizer = TagNormalizer()) {
        self.normalizer = normalizer
    }

    public func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        let text = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            Self.logger.error("Rejected fallback extraction due to empty input")
            throw TagExtractionError.invalidInput
        }

        Self.logger.debug("Running fallback extraction")
        let candidateTokens = tokenize(text)
        Self.logger.debug("Fallback tokenizer produced \(candidateTokens.count) candidates")

        let tags = normalizer.normalize(candidateTokens, config: request.config)

        guard !tags.isEmpty else {
            Self.logger.warning("Fallback extraction produced no quality tags")
            throw TagExtractionError.emptyResult
        }

        Self.logger.debug("Fallback extraction returning \(tags.count) tags")

        return TagExtractionResult(tags: tags, source: .fallback)
    }

    private func tokenize(_ text: String) -> [String] {
        let stopwords = Set([
            "a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "from", "has", "have", "in", "into", "is", "it", "its", "of", "on", "or", "that", "the", "their", "there", "these", "this", "to", "was", "were", "will", "with", "you", "your", "i", "im", "am", "me", "my", "we", "our",
            "show", "find", "looking", "look", "need", "want", "wanting", "get",
            "getting", "search", "searching", "buy", "buying",
            "all", "day", "some", "something", "any", "anything", "please", "would",
            "like", "really"
        ])

        var frequency: [String: Int] = [:]
        let lowered = text.lowercased()
        let parts = lowered.components(separatedBy: CharacterSet.alphanumerics.inverted)

        for part in parts where part.count >= 2 {
            guard !stopwords.contains(part) else {
                continue
            }
            frequency[part, default: 0] += 1
        }

        let sorted = frequency
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .map(\.key)

        return sorted
    }
}
