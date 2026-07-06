import Testing
@testable import FoundationModelWWDC27

struct TagPromptBuilderTests {
    @Test func buildsPromptWithSearchPlanRulesAndSchema() {
        let builder = TagPromptBuilder()
        let request = ProductSearchQueryRequest(
            originalQuery: "Looking for red school uniform for 6 years"
        )

        let prompt = builder.buildPrompt(for: request)

        #expect(prompt.contains("Return only the requested structured output."))
        #expect(prompt.contains("productType = the item the shopper wants to buy."))
        #expect(prompt.contains("Do not use the occasion or activity as the product type."))
        #expect(prompt.contains("Required output fields:"))
        #expect(prompt.contains("productType"))
        #expect(prompt.contains("primaryQuery"))
        #expect(prompt.contains("fallbackQuery"))
        #expect(prompt.contains("Looking for red school uniform for 6 years"))
    }

    @Test func promptInstructsModelToPreserveShopperAgeContext() {
        let builder = TagPromptBuilder()
        let request = ProductSearchQueryRequest(originalQuery: "school uniform for my 6 years old")

        let prompt = builder.buildPrompt(for: request)

        #expect(prompt.contains("Keep the shopper's age or age group when mentioned"))
    }
}
