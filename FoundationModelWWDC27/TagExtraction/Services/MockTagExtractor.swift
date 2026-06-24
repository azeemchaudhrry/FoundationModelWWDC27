import Foundation

public struct MockTagExtractor: TagExtracting, Sendable {
    private let result: Result<TagExtractionResult, Error>

    public init(result: Result<TagExtractionResult, Error>) {
        self.result = result
    }

    public static func success(tags: [String], source: TagExtractionResult.Source = .fallback) -> MockTagExtractor {
        let result = TagExtractionResult(tags: tags.map(Tag.init), source: source)
        return MockTagExtractor(result: .success(result))
    }

    public func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        _ = request
        return try result.get()
    }
}
