import Testing
@testable import FoundationModelWWDC27

struct TagNormalizerTests {
    @Test func lowercasesDeduplicatesAndLimitsCount() {
        let normalizer = TagNormalizer()
        let config = TagExtractionConfig(maxTagCount: 3, lowercase: true, minimumTagLength: 2)

        let normalized = normalizer.normalize([
            " Swift ",
            "swift",
            "iOS",
            "AI",
            "tag",
            ""
        ], config: config)

        #expect(normalized.map(\.value) == ["swift", "ios", "ai"])
    }

    @Test func filtersLowQualityTokens() {
        let normalizer = TagNormalizer()
        let config = TagExtractionConfig(maxTagCount: 5, lowercase: true, minimumTagLength: 3)

        let normalized = normalizer.normalize([
            "a",
            "--",
            "123",
            "content",
            "mobile development"
        ], config: config)

        #expect(normalized.map(\.value) == ["mobile development"])
    }
}
