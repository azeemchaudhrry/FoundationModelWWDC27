import Foundation

public enum TagExtractionError: Error, LocalizedError, Equatable, Sendable {
    case invalidInput
    case modelUnavailable(String)
    case emptyResult

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Input text is empty."
        case .modelUnavailable(let reason):
            return "On-device model unavailable: \(reason)"
        case .emptyResult:
            return "No quality tags were extracted."
        }
    }
}
