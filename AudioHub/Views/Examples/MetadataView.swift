//
//  MetadataView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI

// Example SwiftUI View to use the fetcher
struct MetadataView: View {
	@StateObject private var fetcher: MetadataFetcher

	init(urls: [URL: Data?]) {
		_fetcher = StateObject(wrappedValue: MetadataFetcher(urls: urls))
	}

	var body: some View {
		VStack {
			if fetcher.isFetching {
				ProgressView(value: fetcher.progress) {
					Text("Fetching metadata: \(Int(fetcher.progress * 100))%")
				}
			} else {
				Button("Fetch Metadata") {
					fetcher.fetchMetadata()
				}
			}

			if let error = fetcher.errorMessage {
				Text("Error: \(error)")
					.foregroundColor(.red)
			}

			List(fetcher.metadataResults.sorted(by: { $0.key.lastPathComponent < $1.key.lastPathComponent }), id: \.key) { url, metadata in
				VStack(alignment: .leading) {
					Text("File: \(url.lastPathComponent)")
					if let title = metadata.title {
						Text("Title: \(title)")
					}
					if let artist = metadata.artist {
						Text("Artist: \(artist)")
					}
					if let album = metadata.album {
						Text("Album: \(album)")
					}
					if let artwork = metadata.artwork {
						Text("Artwork size: \(artwork.count) bytes")
					}
				}
			}
		}
	}
}
