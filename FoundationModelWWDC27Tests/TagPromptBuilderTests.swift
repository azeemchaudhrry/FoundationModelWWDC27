import Testing
@testable import FoundationModelWWDC27

struct TagPromptBuilderTests {
    @Test func buildsPromptWithConfiguredMaxCountAndLowercaseRule() {
        let builder = TagPromptBuilder()
        let request = TagExtractionRequest(
            text: "SwiftUI and Foundation Models for keyword extraction",
            config: TagExtractionConfig(maxTagCount: 5, lowercase: true)
        )

        let prompt = builder.buildPrompt(for: request)

        #expect(prompt.contains("Return at most 5 tags."))
        #expect(prompt.contains("Return tags in lowercase."))
        #expect(prompt.contains("SwiftUI and Foundation Models"))
    }
}
