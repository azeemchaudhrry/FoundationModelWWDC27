import Foundation

public enum OnDeviceModelAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

public protocol OnDeviceLanguageModelClient {
    func availability() -> OnDeviceModelAvailability
    func generateSearchQueryPlan(for request: ProductSearchQueryRequest) async throws -> ProductSearchQueryPlan
}
