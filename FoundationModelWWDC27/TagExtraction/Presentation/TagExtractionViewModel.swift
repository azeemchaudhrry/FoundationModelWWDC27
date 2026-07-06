import Foundation
import Combine
import os

struct BatchQueryResult: Identifiable, Sendable {
    let id = UUID()
    let query: String
    let tags: [String]
    let source: String
    let error: String?
}

@MainActor
final class TagExtractionViewModel: ObservableObject {
    private static let logger = Logger(subsystem: "dev.azeem.FoundationModelWWDC27", category: "TagExtractionViewModel")

    @Published var inputText: String = ""
    @Published var tags: [String] = []
    @Published var statusMessage: String = ""
    @Published var modelAvailabilityMessage: String = "Checking model availability..."
    @Published var isLoading: Bool = false
    @Published var batchResults: [BatchQueryResult] = []
    @Published var isBatchRunning: Bool = false

    private let extractor: TagExtracting

    init(extractor: TagExtracting) {
        self.extractor = extractor
    }

    func refreshModelAvailability() {
        guard let provider = extractor as? TagExtractionAvailabilityProviding else {
            modelAvailabilityMessage = "Model availability check unavailable for this extractor"
            Self.logger.notice("Availability provider not implemented by current extractor")
            return
        }

        switch provider.modelAvailability() {
        case .available:
            modelAvailabilityMessage = "Model available"
            Self.logger.debug("Model availability check: available")
        case .unavailable(let reason):
            modelAvailabilityMessage = "Model unavailable: \(humanReadableAvailabilityReason(reason))"
            Self.logger.notice("Model availability check: unavailable - \(reason, privacy: .public)")
        }
    }

    func extract(maxTagCount: Int = 8) async {
        isLoading = true
        defer { isLoading = false }

        Self.logger.debug("Extraction started with maxTagCount=\(maxTagCount)")

        let request = TagExtractionRequest(
            text: inputText,
            config: TagExtractionConfig(maxTagCount: maxTagCount)
        )

        do {
            let result = try await extractor.extractTags(from: request)
            tags = result.values
            statusMessage = "Source: \(result.source.rawValue)"
            Self.logger.debug("Extraction completed successfully with source=\(result.source.rawValue, privacy: .public), count=\(result.values.count)")
        } catch {
            tags = []
            statusMessage = error.localizedDescription
            Self.logger.error("Extraction failed with error: \(error.localizedDescription, privacy: .public)")
        }
    }

    func runBatchAnalysis(queries: [String], maxTagCount: Int = 8) async {
        isBatchRunning = true
        defer { isBatchRunning = false }

        batchResults = []
        Self.logger.notice("Batch analysis started for \(queries.count) queries")

        for (index, query) in queries.enumerated() {
            let request = TagExtractionRequest(
                text: query,
                config: TagExtractionConfig(maxTagCount: maxTagCount)
            )

            do {
                let result = try await extractor.extractTags(from: request)
                batchResults.append(
                    BatchQueryResult(query: query, tags: result.values, source: result.source.rawValue, error: nil)
                )
                Self.logger.notice(
                    "Batch [\(index + 1)/\(queries.count)] query=\"\(query, privacy: .public)\" source=\(result.source.rawValue, privacy: .public) tags=\(result.values, privacy: .public)"
                )
            } catch {
                batchResults.append(
                    BatchQueryResult(query: query, tags: [], source: "error", error: error.localizedDescription)
                )
                Self.logger.error(
                    "Batch [\(index + 1)/\(queries.count)] query=\"\(query, privacy: .public)\" failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        Self.logger.notice("Batch analysis completed for \(queries.count) queries")
    }

    private func humanReadableAvailabilityReason(_ reason: String) -> String {
        switch reason {
        case "device_not_eligible":
            return "This device does not support Apple Intelligence"
        case "apple_intelligence_not_enabled":
            return "Enable Apple Intelligence in Settings"
        case "model_not_ready":
            return "Model is still preparing or downloading"
        case "platform_version_unsupported":
            return "Requires iOS 26+/macOS 26+/visionOS 26+"
        case "foundation_models_unavailable":
            return "Foundation Models framework is unavailable"
        default:
            return reason
        }
    }
}
