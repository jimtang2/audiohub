//
//  Util.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import AVFoundation

struct AudioMetadata {
	let title: String?
	let artist: String?
	let album: String?
	let artwork: Data?
}

func fetchAudioMetadata(from url: URL, bookmarkData: Data? = nil) async throws -> AudioMetadata? {
	var resolvedURL = url
	var stopAccessingResource: (() -> Void)?

	// Handle security-scoped access for SMB URLs
	if let bookmarkData = bookmarkData {
		do {
			var isStale = false
			resolvedURL = try URL(
				resolvingBookmarkData: bookmarkData,
				options: [.withoutUI],
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			)
			if isStale {
				print("Bookmark data is stale for URL: \(url)")
				return nil
			}
			if resolvedURL.startAccessingSecurityScopedResource() {
				stopAccessingResource = { resolvedURL.stopAccessingSecurityScopedResource() }
			}
		} catch {
			print("Failed to resolve bookmark data: \(error)")
			throw error
		}
	}

	defer {
		stopAccessingResource?()
	}

	// Create an AVAsset to read metadata
	let asset = AVURLAsset(url: resolvedURL)

	// Extract metadata
	var title: String?
	var artist: String?
	var album: String?
	var artwork: Data?

	for item in try await asset.load(.metadata) {
		guard let key = item.commonKey?.rawValue else { continue }
		switch key {
		case AVMetadataKey.commonKeyTitle.rawValue:
			title = try await item.load(.stringValue)
		case AVMetadataKey.commonKeyArtist.rawValue:
			artist = try await item.load(.stringValue)
		case AVMetadataKey.commonKeyAlbumName.rawValue:
			album = try await item.load(.stringValue)
		case AVMetadataKey.commonKeyArtwork.rawValue:
			artwork = try await item.load(.dataValue)
		default:
			break
		}
	}

	// Return metadata if at least one field is present
	if title == nil, artist == nil, album == nil, artwork == nil {
		return nil
	}

	return AudioMetadata(title: title, artist: artist, album: album, artwork: artwork)
}
