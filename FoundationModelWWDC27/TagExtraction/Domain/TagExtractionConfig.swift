import Foundation

public struct TagExtractionConfig: Sendable, Equatable {
    public static let `default` = TagExtractionConfig()

    public var maxTagCount: Int
    public var lowercase: Bool
    public var minimumTagLength: Int

    public init(
        maxTagCount: Int = 8,
        lowercase: Bool = true,
        minimumTagLength: Int = 2
    ) {
        self.maxTagCount = max(1, maxTagCount)
        self.lowercase = lowercase
        self.minimumTagLength = max(1, minimumTagLength)
    }
}
