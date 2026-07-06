import Testing
@testable import FoundationModelWWDC27

@MainActor
struct TagExtractionViewModelTests {
    @Test func runBatchAnalysisCollectsResultForEachQueryInOrder() async {
        let extractor = QueryEchoingExtractor()
        let viewModel = TagExtractionViewModel(extractor: extractor)

        await viewModel.runBatchAnalysis(queries: ["red shirt", "blue jeans"])

        #expect(viewModel.batchResults.map(\.query) == ["red shirt", "blue jeans"])
        #expect(viewModel.batchResults[0].tags == ["red", "shirt"])
        #expect(viewModel.batchResults[1].tags == ["blue", "jeans"])
        #expect(viewModel.batchResults.allSatisfy { $0.error == nil })
        #expect(viewModel.isBatchRunning == false)
    }

    @Test func runBatchAnalysisRecordsErrorWhenExtractionFails() async {
        let extractor = FailingExtractor()
        let viewModel = TagExtractionViewModel(extractor: extractor)

        await viewModel.runBatchAnalysis(queries: ["anything"])

        #expect(viewModel.batchResults.count == 1)
        #expect(viewModel.batchResults[0].tags.isEmpty)
        #expect(viewModel.batchResults[0].error != nil)
    }
}

private struct QueryEchoingExtractor: TagExtracting {
    func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        let words = request.text.split(separator: " ").map(String.init)
        return TagExtractionResult(tags: words.map(Tag.init), source: .fallback)
    }
}

private struct FailingExtractor: TagExtracting {
    func extractTags(from request: TagExtractionRequest) async throws -> TagExtractionResult {
        throw TagExtractionError.invalidInput
    }
}
