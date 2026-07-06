import Testing
@testable import FoundationModelWWDC27

struct RuleBasedCatalogueQueryExtractorTests {
    @Test func matchesExpectedQueries() {
        let extractor = RuleBasedCatalogueQueryExtractor()

        let testCases: [(input: String, productType: String, primary: String, fallback: String)] = [
            (
                "I am looking for a green shirt for tropical weather.",
                "shirt",
                "green breathable shirt",
                "green shirt"
            ),
            (
                "I need a black dress for a cocktail party this weekend.",
                "dress",
                "black cocktail dress",
                "black dress"
            ),
            (
                "Show me comfortable white sneakers for walking all day.",
                "sneakers",
                "comfortable white walking sneakers",
                "white sneakers"
            ),
            (
                "I am looking for a waterproof backpack for college and daily commuting.",
                "backpack",
                "waterproof commuter backpack",
                "waterproof backpack"
            ),
            (
                "Find me a lightweight jacket for cold mornings but warm afternoons.",
                "jacket",
                "lightweight transitional jacket",
                "lightweight jacket"
            ),
            (
                "I want a red swimsuit for a beach vacation.",
                "swimsuit",
                "red swimsuit",
                "red swimwear"
            ),
            (
                "I need formal shoes for a wedding, preferably brown leather.",
                "formal shoes",
                "brown leather formal shoes",
                "formal shoes"
            ),
            (
                "Looking for breathable gym shorts for running in hot weather.",
                "gym shorts",
                "breathable running gym shorts",
                "running shorts"
            ),
            (
                "I want a soft oversized hoodie for winter travel.",
                "hoodie",
                "soft oversized hoodie",
                "oversized hoodie"
            ),
            (
                "Find me a blue linen shirt for a summer vacation.",
                "linen shirt",
                "blue linen shirt",
                "linen shirt"
            ),
            (
                "I need a small crossbody bag for traveling and carrying my phone and passport.",
                "crossbody bag",
                "small travel crossbody bag",
                "small crossbody bag"
            ),
            (
                "Looking for a school uniform for my 6 years old in red",
                "school uniform",
                "red school uniform 6 years",
                "kids red school uniform"
            )
        ]

        for testCase in testCases {
            let plan = extractor.extract(from: testCase.input)
            #expect(plan.productType == testCase.productType)
            #expect(plan.primaryQuery == testCase.primary)
            #expect(plan.fallbackQuery == testCase.fallback)
        }
    }
}