//
//  FoundationModelWWDC27App.swift
//  FoundationModelWWDC27
//
//  Created by Azeem, Hafiz Muhammad on 24/06/2026.
//

import SwiftUI

@main
struct FoundationModelWWDC27App: App {
    private let extractor: TagExtracting

    init() {
        self.extractor = TagExtractorFactory.makeDefault()
    }

    init(extractor: TagExtracting) {
        self.extractor = extractor
    }

    var body: some Scene {
        WindowGroup {
            ContentView(extractor: extractor)
        }
    }
}
