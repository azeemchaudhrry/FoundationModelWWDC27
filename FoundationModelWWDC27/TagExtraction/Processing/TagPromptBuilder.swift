import Foundation

public struct TagPromptBuilder: Sendable {
    public init() {}

    public func buildPrompt(for request: ProductSearchQueryRequest) -> String {
        let input = request.originalQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
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

        Required output fields:
        productType
        primaryQuery
        fallbackQuery

        Shopper query:
        \(input)
        """
    }
}
