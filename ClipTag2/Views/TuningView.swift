//
//  TuningView.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import SwiftUI

struct TuningView: View {
    @Bindable var model: AnalysisViewModel

    var body: some View {
        NavigationStack {
            Form {
                rerunSection
                samplingSection
                classificationSection
                sceneSection
                performanceSection
                thumbnailSection

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        model.resetSettings()
                    }
                }
            }
            .navigationTitle("Tuning")
        }
    }

    @ViewBuilder
    private var rerunSection: some View {
        Section {
            Button {
                model.reanalyze()
            } label: {
                HStack {
                    Label("Re-analyze Clip", systemImage: "arrow.clockwise")
                    Spacer()
                    if model.isBusy { ProgressView() }
                }
            }
            .disabled(!model.canReanalyze)
        } footer: {
            if model.sourceURL == nil {
                Text("Analyze a clip first — these settings then re-run against it without re-importing.")
            } else if model.hasUnappliedChanges {
                Text("Settings have changed since the last run.")
                    .foregroundStyle(.orange)
            } else {
                Text("The current result reflects these settings.")
            }
        }
    }

    private var samplingSection: some View {
        Section {
            TunableSlider(
                title: "Frames per second",
                value: $model.settings.samplesPerSecond,
                range: 0.25...4,
                step: 0.25,
                format: "%.2f"
            )
            Stepper(
                "Frame cap: \(model.settings.maximumFrames)",
                value: $model.settings.maximumFrames,
                in: 20...240,
                step: 10
            )
        } header: {
            Text("Sampling")
        } footer: {
            Text("Higher sampling catches shorter shots but multiplies analysis cost. Past the cap, the interval widens to cover the clip evenly.")
        }
    }

    private var classificationSection: some View {
        Section {
            TunableSlider(
                title: "Minimum confidence",
                value: $model.settings.minimumConfidence,
                range: 0...0.5,
                step: 0.01,
                format: "%.2f"
            )
            Stepper(
                "Labels per frame: \(model.settings.maximumClassifications)",
                value: $model.settings.maximumClassifications,
                in: 1...10
            )
        } header: {
            Text("Classification")
        } footer: {
            Text("Raise the floor to cut noisy low-confidence labels out of the tag list.")
        }
    }

    private var sceneSection: some View {
        Section {
            TunableSlider(
                title: "Cut threshold",
                value: $model.settings.cutThreshold,
                range: 4...40,
                step: 0.5,
                format: "%.1f"
            )
        } header: {
            Text("Scene Detection")
        } footer: {
            Text("Feature-print distance above which two consecutive frames count as different scenes. Lower finds more cuts; too low and camera motion registers as one.")
        }
    }

    private var performanceSection: some View {
        Section {
            Stepper(
                "Concurrent lanes: \(model.settings.concurrency)",
                value: $model.settings.concurrency,
                in: 1...8
            )
        } header: {
            Text("Performance")
        } footer: {
            Text("How many frames are analyzed at once. Set to 1 for the serial baseline, then compare milliseconds per frame on the Analyze tab.")
        }
    }

    private var thumbnailSection: some View {
        Section {
            TunableSlider(
                title: "Sharpness",
                value: $model.settings.sharpnessWeight,
                range: 0...1,
                step: 0.05,
                format: "%.2f"
            )
            TunableSlider(
                title: "Subject confidence",
                value: $model.settings.confidenceWeight,
                range: 0...1,
                step: 0.05,
                format: "%.2f"
            )
            TunableSlider(
                title: "Face present",
                value: $model.settings.faceWeight,
                range: 0...1,
                step: 0.05,
                format: "%.2f"
            )
        } header: {
            Text("Thumbnail Weights")
        } footer: {
            Text("Normalized before scoring, so only the ratio between them matters.")
        }
    }
}

private struct TunableSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}
