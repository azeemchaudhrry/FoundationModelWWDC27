import Foundation

public struct ProductSearchQueryRequest: Sendable, Equatable {
    public let originalQuery: String
    public let config: TagExtractionConfig

    public init(originalQuery: String, config: TagExtractionConfig = .default) {
        self.originalQuery = originalQuery
        self.config = config
    }
}