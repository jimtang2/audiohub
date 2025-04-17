//
//  MetadataFetcher.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI
import AVFoundation

// ViewModel to manage metadata fetching
class MetadataFetcher: ObservableObject {
	@Published var metadataResults: [URL: AudioMetadata] = [:]
	@Published var progress: Double = 0.0
	@Published var isFetching: Bool = false
	@Published var errorMessage: String?

	private let batchSize = 10 // Number of files to process concurrently
	private let urls: [URL: Data?] // URLs and their bookmarkData

	init(urls: [URL: Data?]) {
		self.urls = urls
	}

	func fetchMetadata() {
		Task.detached(priority: .userInitiated) {
			await self.processFiles()
		}
	}

	private func processFiles() async {
		await MainActor.run {
			self.isFetching = true
			self.progress = 0.0
			self.errorMessage = nil
		}

		let totalFiles = self.urls.count
		var processedCount = 0
		var currentBatch: [URL: Data?] = [:]

		for (url, bookmarkData) in self.urls {
			currentBatch[url] = bookmarkData
			if currentBatch.count >= self.batchSize || processedCount + currentBatch.count == totalFiles {
				await processBatch(currentBatch)

				// Update processedCount and capture its value
				processedCount += currentBatch.count
				let currentProcessed = processedCount // Capture the current value

				// Update progress on the main thread using the captured value
				await MainActor.run {
					self.progress = Double(currentProcessed) / Double(totalFiles)
				}
				currentBatch.removeAll()
			}
		}

		await MainActor.run {
			self.isFetching = false
		}
	}

	private func processBatch(_ batch: [URL: Data?]) async {
		await withTaskGroup(of: (URL, AudioMetadata?).self) { group in
			for (url, bookmarkData) in batch {
				group.addTask {
					do {
						let metadata = try await fetchAudioMetadata(from: url, bookmarkData: bookmarkData)
						return (url, metadata)
					} catch {
						await MainActor.run {
							self.errorMessage = "Failed to fetch metadata for \(url.lastPathComponent): \(error)"
						}
						return (url, nil)
					}
				}
			}

			for await (url, metadata) in group {
				if let metadata = metadata {
					await MainActor.run {
						self.metadataResults[url] = metadata
					}
				}
			}
		}
	}
}



//// Example usage
//let urls: [URL: Data?] = [
//	URL(string: "smb://server/share/file1.m4a")!: nil,
//	URL(string: "smb://server/share/file2.mp3")!: someBookmarkData,
//	// ... thousands more URLs ...
//]
//let view = MetadataView(urls: urls)
