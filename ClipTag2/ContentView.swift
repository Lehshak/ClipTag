//
//  ContentView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import SwiftUI

struct ContentView: View {
    @State private var model = AnalysisViewModel()

    var body: some View {
        TabView {
            AnalyzeView(model: model)
                .tabItem { Label("Analyze", systemImage: "wand.and.stars") }

            FramesView(model: model)
                .tabItem { Label("Frames", systemImage: "square.grid.2x2") }

            TuningView(model: model)
                .tabItem { Label("Tuning", systemImage: "slider.horizontal.3") }
        }
    }
}
