//
//  ContentView.swift
//  FoundationModelWWDC27
//
//  Created by Azeem, Hafiz Muhammad on 24/06/2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @StateObject private var viewModel: TagExtractionViewModel
    @State private var copyStatus: String = ""

    private let quickInjectSamples: [String] = [
        "I am looking for a green shirt for tropical weather.",
        "I need a black dress for a cocktail party this weekend.",
        "Show me comfortable white sneakers for walking all day.",
        "I am looking for a waterproof backpack for college and daily commuting.",
        "Find me a lightweight jacket for cold mornings but warm afternoons.",
        "I want a red swimsuit for a beach vacation.",
        "I need formal shoes for a wedding, preferably brown leather.",
        "Looking for breathable gym shorts for running in hot weather.",
        "I want a soft oversized hoodie for winter travel.",
        "Find me a blue linen shirt for a summer vacation.",
        "I need a small crossbody bag for traveling and carrying my phone and passport.",
        "Looking for a school uniform for my 6 years old in red"
    ]

    init(extractor: TagExtracting) {
        _viewModel = StateObject(wrappedValue: TagExtractionViewModel(extractor: extractor))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tag Extraction")
                    .font(.title2.weight(.semibold))

                TextEditor(text: $viewModel.inputText)
                    .frame(height: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                Text("Quick Inject")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickInjectSamples, id: \.self) { sample in
                            Button(sample) {
                                viewModel.inputText = sample
                            }
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                HStack {
                    Button("Extract Tags") {
                        Task {
                            await viewModel.extract(maxTagCount: 8)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Copy Tags") {
                        copyTagsToClipboard(viewModel.tags)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.tags.isEmpty)

                    if viewModel.isLoading {
                        ProgressView()
                    }
                }

                if !copyStatus.isEmpty {
                    Text(copyStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if viewModel.tags.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("Foundation Model")
        }
    }

    private func copyTagsToClipboard(_ tags: [String]) {
        let joined = tags.joined(separator: ", ")
        guard !joined.isEmpty else {
            copyStatus = "No tags to copy"
            return
        }

#if canImport(UIKit)
        UIPasteboard.general.string = joined
        copyStatus = "Copied \(tags.count) tags"
#elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(joined, forType: .string)
        copyStatus = "Copied \(tags.count) tags"
#else
        copyStatus = "Clipboard is unavailable on this platform"
#endif
    }
}

#Preview {
    ContentView(extractor: MockTagExtractor.success(tags: ["swift", "ios", "foundation models"]))
}
