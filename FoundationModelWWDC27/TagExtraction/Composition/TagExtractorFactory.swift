import Foundation

public enum TagExtractorFactory {
    public static func makeDefault() -> TagExtracting {
        let fallback = FallbackKeywordExtractor()
        let client = AppleOnDeviceLanguageModelClient()
        return SLMTagExtractor(modelClient: client, fallback: fallback)
    }
}
