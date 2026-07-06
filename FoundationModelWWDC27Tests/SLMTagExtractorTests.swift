import Foundation
import Testing
@testable import FoundationModelWWDC27

@MainActor
struct SLMTagExtractorTests {
    @Test func usesOnDeviceModelWhenAvailableAndPrimaryQueryIsStrong() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "framework",
                primaryQuery: "swift ios foundation models framework",
                fallbackQuery: "foundation models framework"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Build with Foundation Models")
        )

        #expect(result.source == .onDeviceModel)
        #expect(result.values.contains("framework"))
        #expect(result.values.contains("swift"))
        #expect(result.values.contains("ios"))
    }

    @Test func fallsBackWhenModelUnavailable() async throws {
        let client = StubOnDeviceClient(
            availability: .unavailable("device_not_eligible"),
            generatedPlan: ProductSearchQueryPlan(
                productType: "shirt",
                primaryQuery: "shirt",
                fallbackQuery: "shirt"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback", "keywords"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "some text")
        )

        #expect(result.source == .fallback)
        #expect(result.values == ["fallback", "keywords"])
    }

    @Test func usesFallbackQueryWhenPrimaryQueryIsWeak() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "uniform",
                primaryQuery: "uniform",
                fallbackQuery: "school kids uniform"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["recovered"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Need a school uniform")
        )

        #expect(result.source == .onDeviceModel)
        #expect(result.values.contains("uniform"))
        #expect(result.values.contains("school"))
        #expect(result.values.contains("kids"))
    }

    @Test func passesMappedRequestToModelClient() async throws {
        let client = RequestCapturingOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "framework",
                primaryQuery: "swift framework",
                fallbackQuery: "framework"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])
        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)

        let config = TagExtractionConfig(maxTagCount: 5, lowercase: false)
        _ = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Build with Foundation Models", config: config)
        )

        #expect(client.receivedRequest?.originalQuery == "Build with Foundation Models")
        #expect(client.receivedRequest?.config.maxTagCount == 5)
        #expect(client.receivedRequest?.config.lowercase == false)
    }

    @Test func rejectsInvalidGeneratedTermsAndUsesDeterministicFallback() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "dress",
                primaryQuery: "product search dress",
                fallbackQuery: "black dress"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "I need a black dress for a cocktail party this weekend.")
        )

        #expect(result.source == .onDeviceModel)
        #expect(result.values.contains("dress"))
        #expect(result.values.contains("cocktail"))
    }

    @Test func rejectsContextAsProductTypeAndUsesDeterministicFallback() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "wedding",
                primaryQuery: "brown leather wedding",
                fallbackQuery: "wedding"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "I need formal shoes for a wedding, preferably brown leather.")
        )

        #expect(result.source == .onDeviceModel)
        #expect(result.values.contains("formal shoes"))
        #expect(result.values.contains("brown"))
    }

    @Test func doesNotDuplicateWholeQueryAlongsideItsIndividualWords() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "dress",
                primaryQuery: "black cocktail dress",
                fallbackQuery: "black dress"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "I need a black dress for a cocktail party this weekend.")
        )

        #expect(result.values == ["dress", "black", "cocktail"])
    }

    @Test func excludesProductTypeWordsFromIndividualTokensToAvoidOverlap() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "school uniform",
                primaryQuery: "red school uniform",
                fallbackQuery: "kids red school uniform"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Looking for a school uniform for my 6 years old in red")
        )

        #expect(result.values == ["school uniform", "red"])
    }

    @Test func preservesAgePhraseAsASingleTagInsteadOfSplittingIt() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedPlan: ProductSearchQueryPlan(
                productType: "school uniform",
                primaryQuery: "red school uniform 6 years",
                fallbackQuery: "kids red school uniform"
            )
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Looking for a school uniform for my 6 years old in red")
        )

        #expect(result.values == ["school uniform", "red", "6 years"])
    }
}

private struct StubOnDeviceClient: OnDeviceLanguageModelClient {
    let availabilityStatus: OnDeviceModelAvailability
    let generatedPlan: ProductSearchQueryPlan

    init(availability: OnDeviceModelAvailability, generatedPlan: ProductSearchQueryPlan) {
        self.availabilityStatus = availability
        self.generatedPlan = generatedPlan
    }

    func availability() -> OnDeviceModelAvailability {
        availabilityStatus
    }

    func generateSearchQueryPlan(for request: ProductSearchQueryRequest) async throws -> ProductSearchQueryPlan {
        _ = request
        return generatedPlan
    }
}

private final class RequestCapturingOnDeviceClient: OnDeviceLanguageModelClient, @unchecked Sendable {
    let availabilityStatus: OnDeviceModelAvailability
    let generatedPlan: ProductSearchQueryPlan
    private(set) var receivedRequest: ProductSearchQueryRequest?

    init(availability: OnDeviceModelAvailability, generatedPlan: ProductSearchQueryPlan) {
        self.availabilityStatus = availability
        self.generatedPlan = generatedPlan
    }

    func availability() -> OnDeviceModelAvailability {
        availabilityStatus
    }

    func generateSearchQueryPlan(for request: ProductSearchQueryRequest) async throws -> ProductSearchQueryPlan {
        receivedRequest = request
        return generatedPlan
    }
}
