import Foundation

public enum OnDeviceModelAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

public struct OnDeviceModelTagCandidate: Equatable, Sendable {
    public let value: String
    public let confidence: Double?

    public init(value: String, confidence: Double?) {
        self.value = value
        self.confidence = confidence
    }
}

public protocol OnDeviceLanguageModelClient {
    func availability() -> OnDeviceModelAvailability
    func generateTagCandidates(for query: String) async throws -> [OnDeviceModelTagCandidate]
}
