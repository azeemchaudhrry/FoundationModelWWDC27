import Foundation

public struct TagPromptBuilder: Sendable {
    public init() {}

    public func buildPrompt(for request: TagExtractionRequest) -> String {
        let caseRule = request.config.lowercase
            ? "- Return tags in lowercase."
            : "- Preserve original casing when useful."
        let input = request.text.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        You extract high-quality ecommerce search tags from a shopper query.

        Rules:
        - Return at most \(request.config.maxTagCount) tags.
        \(caseRule)
        - Focus on product type, color, material, use case, activity, fit, style, weather, occasion, and key attributes.
        - Ignore filler and command words such as show, me, find, looking, need, want, for, all, day, the, a, an.
        - Keep meaningful phrases together (for example: white sneakers).
        - Return only tags that improve catalog search and filtering.
        - Keep tags concise (1-3 words).

        Shopper query:
        \(input)
        """
    }
}
