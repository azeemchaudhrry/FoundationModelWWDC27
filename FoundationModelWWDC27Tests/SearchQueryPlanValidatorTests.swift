import Foundation
import Testing
@testable import FoundationModelWWDC27

struct SearchQueryPlanValidatorTests {
    @Test func detectsInvalidGeneratedTerms() {
        let validator = SearchQueryPlanValidator()

        #expect(validator.containsInvalidGeneratedTerm("product search dress"))
        #expect(!validator.containsInvalidGeneratedTerm("soft oversized hoodie"))
    }

    @Test func validatesOrFallsBackToRuleBasedExtractor() {
        let validator = SearchQueryPlanValidator()
        let invalidPlan = ProductSearchQueryPlan(
            productType: "dress",
            primaryQuery: "product search dress",
            fallbackQuery: "black dress"
        )

        let validated = validator.validateOrFallback(
            plan: invalidPlan,
            originalQuery: "I need a black dress for a cocktail party this weekend."
        )

        #expect(validated.productType == "dress")
        #expect(validated.primaryQuery == "black cocktail dress")
        #expect(validated.fallbackQuery == "black dress")
    }

    @Test func buildsEncodedCatalogueUrl() {
        let validator = SearchQueryPlanValidator()
        let url = validator.makeCatalogueSearchURL(query: "red school uniform 6 years")

        #expect(url?.absoluteString == "https://www.next.co.uk/search?w=red%20school%20uniform%206%20years")
    }
}