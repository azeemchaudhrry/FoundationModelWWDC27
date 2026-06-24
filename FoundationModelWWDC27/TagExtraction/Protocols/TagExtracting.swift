import Foundation

public protocol TagExtracting {
    func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult
}
