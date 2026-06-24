import Foundation
import Testing
@testable import FoundationModelWWDC27

struct SLMTagExtractorTests {
    @Test func usesOnDeviceModelWhenAvailableAndValid() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedCandidates: [
                OnDeviceModelTagCandidate(value: "swift", confidence: 0.99),
                OnDeviceModelTagCandidate(value: "ios", confidence: 0.97),
                OnDeviceModelTagCandidate(value: "foundation models", confidence: 0.95)
            ]
        )
        let fallback = MockTagExtractor.success(tags: ["fallback"])

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "Build with Foundation Models")
        )

        #expect(result.source == .onDeviceModel)
        #expect(result.values == ["swift", "ios", "foundation models"])
    }

    @Test func fallsBackWhenModelUnavailable() async throws {
        let client = StubOnDeviceClient(
            availability: .unavailable("device_not_eligible"),
            generatedCandidates: [
                OnDeviceModelTagCandidate(value: "swift", confidence: 0.9),
                OnDeviceModelTagCandidate(value: "ios", confidence: 0.8)
            ]
        )
        let fallback = MockTagExtractor.success(tags: ["fallback", "keywords"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "some text")
        )

        #expect(result.source == .fallback)
        #expect(result.values == ["fallback", "keywords"])
    }

    @Test func fallsBackWhenGeneratedTagsNormalizeToEmpty() async throws {
        let client = StubOnDeviceClient(
            availability: .available,
            generatedCandidates: [
                OnDeviceModelTagCandidate(value: "tags", confidence: 0.9),
                OnDeviceModelTagCandidate(value: "keywords", confidence: 0.8)
            ]
        )
        let fallback = MockTagExtractor.success(tags: ["recovered"], source: .fallback)

        let extractor = SLMTagExtractor(modelClient: client, fallback: fallback)
        let result = try await extractor.extractTags(
            from: TagExtractionRequest(text: "some text")
        )

        #expect(result.source == .fallback)
        #expect(result.values == ["recovered"])
    }
}

private struct StubOnDeviceClient: OnDeviceLanguageModelClient {
    let availabilityStatus: OnDeviceModelAvailability
    let generatedCandidates: [OnDeviceModelTagCandidate]

    init(availability: OnDeviceModelAvailability, generatedCandidates: [OnDeviceModelTagCandidate]) {
        self.availabilityStatus = availability
        self.generatedCandidates = generatedCandidates
    }

    func availability() -> OnDeviceModelAvailability {
        availabilityStatus
    }

    func generateTagCandidates(for prompt: String) async throws -> [OnDeviceModelTagCandidate] {
        _ = prompt
        return generatedCandidates
    }
}
