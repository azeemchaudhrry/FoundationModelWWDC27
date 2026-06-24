import Foundation

public struct TagExtractionResult: Sendable, Equatable {
    public enum Source: String, Sendable {
        case onDeviceModel
        case fallback
    }

    public let tags: [Tag]
    public let source: Source

    public init(tags: [Tag], source: Source) {
        self.tags = tags
        self.source = source
    }

    public var values: [String] {
        tags.map(\.value)
    }
}
