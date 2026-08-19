//
//  AnalyzeView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import PhotosUI
import SwiftUI

struct AnalyzeView: View {
    @Bindable var model: AnalysisViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .idle:
                    ImportPrompt(selection: $model.selection)

                case .loading:
                    ProgressStatus(
                        title: "Loading clip",
                        detail: "Copying the video out of your library.",
                        progress: nil
                    )

                case .analyzing(let progress):
                    ProgressStatus(
                        title: "Analyzing frames",
                        detail: "Classification, face detection, and feature prints run on every sampled frame.",
                        progress: progress
                    )

                case .finished(let result):
                    ResultsView(result: result)

                case .failed(let message):
                    FailureView(message: message) { model.reset() }
                }
            }
            .navigationTitle("ClipTag")
            .toolbar {
                // Kept in the bar at all times and hidden when idle. Inserting and
                // removing the item instead makes UIKit lay out a zero-width
                // wrapper mid-transition and log unsatisfiable constraints.
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Clip") { model.reset() }
                        .opacity(model.result != nil ? 1 : 0)
                        .disabled(model.result == nil)
                        .accessibilityHidden(model.result == nil)
                }
            }
        }
    }
}

private struct ImportPrompt: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        ContentUnavailableView {
            Label("Tag a Clip", systemImage: "wand.and.stars")
        } description: {
            Text("Pick a short video. ClipTag samples keyframes, classifies each one, finds scene cuts, and picks a thumbnail — entirely on device.")
        } actions: {
            PhotosPicker(selection: $selection, matching: .videos, photoLibrary: .shared()) {
                Text("Choose Video").font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

private struct ProgressStatus: View {
    let title: String
    let detail: String
    let progress: Double?

    var body: some View {
        VStack(spacing: 24) {
            if let progress {
                ProgressView(value: progress) {
                    Text(title).font(.headline)
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            } else {
                ProgressView().controlSize(.large)
                Text(title).font(.headline)
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

private struct FailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Analysis Failed", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Another Clip", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
