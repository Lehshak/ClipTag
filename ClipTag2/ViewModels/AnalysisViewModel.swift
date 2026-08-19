//
//  AnalysisViewModel.swift
//  ClipTag
//
//  Created by Lehshak Teelockchand on 2026-08-17.
//

import CoreTransferable
import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

nonisolated struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            // The picker deletes its copy once the transfer returns, so take our own.
            let destination = URL.temporaryDirectory
                .appending(path: "cliptag-\(UUID().uuidString).mov")
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return VideoFile(url: destination)
        }
    }
}

@MainActor
@Observable
final class AnalysisViewModel {
    enum State {
        case idle
        case loading
        case analyzing(progress: Double)
        case finished(AnalysisResult)
        case failed(String)
    }

    private(set) var state: State = .idle

    var settings = AnalysisSettings()

    /// The imported clip is kept on disk after analysis so the Tuning tab can
    /// re-run against it without making the user pick the video again.
    private(set) var sourceURL: URL?

    /// The settings the current result was produced with, so the UI can tell the
    /// user their changes haven't been applied yet.
    private(set) var appliedSettings: AnalysisSettings?

    var selection: PhotosPickerItem? {
        didSet {
            guard let selection else { return }
            Task { await load(selection) }
        }
    }

    var result: AnalysisResult? {
        if case .finished(let result) = state { return result }
        return nil
    }

    var isBusy: Bool {
        switch state {
        case .loading, .analyzing: true
        default: false
        }
    }

    var canReanalyze: Bool { sourceURL != nil && !isBusy }

    var hasUnappliedChanges: Bool {
        guard let appliedSettings else { return false }
        return appliedSettings != settings
    }

    func reanalyze() {
        guard let sourceURL, !isBusy else { return }
        Task { await run(url: sourceURL) }
    }

    func resetSettings() {
        settings = AnalysisSettings()
    }

    func reset() {
        discardSource()
        selection = nil
        state = .idle
    }

    private func load(_ item: PhotosPickerItem) async {
        state = .loading
        discardSource()

        do {
            guard let video = try await item.loadTransferable(type: VideoFile.self) else {
                state = .failed("That item could not be loaded as a video.")
                return
            }
            sourceURL = video.url
            await run(url: video.url)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func run(url: URL) async {
        state = .analyzing(progress: 0)

        var analyzer = VideoAnalyzer()
        analyzer.settings = settings

        do {
            // analyze is a nonisolated async call, so the per-frame Vision work
            // runs off the main actor and the progress bar keeps animating.
            let result = try await analyzer.analyze(url: url) { [weak self] progress in
                Task { @MainActor in
                    guard let self, case .analyzing = self.state else { return }
                    self.state = .analyzing(progress: progress)
                }
            }
            appliedSettings = result.settings
            state = .finished(result)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func discardSource() {
        if let sourceURL {
            try? FileManager.default.removeItem(at: sourceURL)
        }
        sourceURL = nil
        appliedSettings = nil
    }
}
