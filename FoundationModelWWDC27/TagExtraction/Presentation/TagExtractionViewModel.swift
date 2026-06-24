import Foundation
import Combine

@MainActor
final class TagExtractionViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var tags: [String] = []
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false

    private let extractor: TagExtracting

    init(extractor: TagExtracting) {
        self.extractor = extractor
    }

    func extract(maxTagCount: Int = 8) async {
        isLoading = true
        defer { isLoading = false }

        let request = TagExtractionRequest(
            text: inputText,
            config: TagExtractionConfig(maxTagCount: maxTagCount)
        )

        do {
            let result = try await extractor.extractTags(from: request)
            tags = result.values
            statusMessage = "Source: \(result.source.rawValue)"
        } catch {
            tags = []
            statusMessage = error.localizedDescription
        }
    }
}
