import Foundation

public protocol TagExtracting {
    func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult
}

public enum TagExtractionModelAvailability: Sendable, Equatable {
    case available
    case unavailable(String)
}

public protocol TagExtractionAvailabilityProviding {
    func modelAvailability() -> TagExtractionModelAvailability
}
