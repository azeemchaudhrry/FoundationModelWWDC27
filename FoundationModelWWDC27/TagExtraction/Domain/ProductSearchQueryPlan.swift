import Foundation

public struct ProductSearchQueryPlan: Sendable, Equatable {
    public let productType: String
    public var primaryQuery: String
    public var fallbackQuery: String

    public init(
        productType: String,
        primaryQuery: String,
        fallbackQuery: String
    ) {
        self.productType = productType
        self.primaryQuery = primaryQuery
        self.fallbackQuery = fallbackQuery
    }
}