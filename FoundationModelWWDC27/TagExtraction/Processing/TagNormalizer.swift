import Foundation

public struct TagNormalizer: Sendable {
    private let blockedTerms: Set<String> = [
        "tag", "tags", "keyword", "keywords", "text", "content", "article", "topic", "topics", "none", "n/a", "na"
    ]

    public init() {}

    public func normalize(_ rawTags: [String], config: TagExtractionConfig) -> [Tag] {
        let maxCount = max(1, config.maxTagCount)
        let minimumLength = max(1, config.minimumTagLength)

        var seen = Set<String>()
        var normalized: [Tag] = []

        for raw in rawTags {
            guard let sanitized = sanitize(raw) else {
                continue
            }

            let dedupeKey = sanitized.lowercased()
            guard dedupeKey.count >= minimumLength else {
                continue
            }
            guard dedupeKey.rangeOfCharacter(from: .letters) != nil else {
                continue
            }
            guard !blockedTerms.contains(dedupeKey) else {
                continue
            }
            guard seen.insert(dedupeKey).inserted else {
                continue
            }

            let finalValue = config.lowercase ? dedupeKey : sanitized
            normalized.append(Tag(finalValue))

            if normalized.count == maxCount {
                break
            }
        }

        return normalized
    }

    private func sanitize(_ text: String) -> String? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return nil
        }

        cleaned = cleaned.replacingOccurrences(
            of: #"^[\p{P}\p{S}\s]+"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"[\p{P}\p{S}\s]+$"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        guard !cleaned.isEmpty, cleaned.count <= 40 else {
            return nil
        }

        return cleaned
    }
}
