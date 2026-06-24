import Foundation

public struct TagExtractionRequest: Sendable, Equatable {
    public let text: String
    public let config: TagExtractionConfig

    public init(text: String, config: TagExtractionConfig = .default) {
        self.text = text
        self.config = config
    }
}
