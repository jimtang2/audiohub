//
//  Util.swift
//  AudioHub
//
//  Created by Jimmy Tang on 18/4/2025.
//

import AVFoundation
import SwiftData
import SwiftUI

func isFirstLaunch() -> Bool {
	return Settings.shared.url == nil
}

func canAccessURL() -> Bool {
	guard let url = Settings.shared.url else {
		return false
	}
	let needsStopAccessing = url.startAccessingSecurityScopedResource()
	defer {
		if needsStopAccessing {
			url.stopAccessingSecurityScopedResource()
		}
	}
	if !FileManager.default.fileExists(atPath: url.path) {
		return false
	}
	do {
		let _ = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
		return true
	} catch {
		return false
	}
}

func saveBookmarkData() throws {
	guard let url = Settings.shared.url else {
		return
	}
	let needsStopAccessing = url.startAccessingSecurityScopedResource()
	defer {
		if needsStopAccessing {
			url.stopAccessingSecurityScopedResource()
		}
	}
	Settings.shared.bookmarkData = try url.bookmarkData(
		options: [
//			.suitableForBookmarkFile,
//			.minimalBookmark
		],
		includingResourceValuesForKeys: [
			.nameKey,
			.isDirectoryKey,
			.volumeIdentifierKey,
			.fileResourceIdentifierKey,
			.creationDateKey
		],
		relativeTo: url
	)
}

func canUseBookmarkData() throws -> Bool {
	guard let bookmarkData = Settings.shared.bookmarkData else {
		return false
	}
	var isStale = false
	guard let url = try? URL(
		resolvingBookmarkData: bookmarkData,
		options: [],
		relativeTo: nil,
		bookmarkDataIsStale: &isStale
	) else {
		return false
	}
	Settings.shared.url = url

	if isStale {
		Settings.shared.bookmarkData = nil
	}

	return true
}

func getEnumeratorResourceKeys() -> [URLResourceKey] {
	return [
		.isDirectoryKey,
		.nameKey,
		.totalFileSizeKey,
		.contentModificationDateKey
	]
}

func getEnumerator(for url: URL) -> FileManager.DirectoryEnumerator? {
	return FileManager.default.enumerator(
		at: url,
		includingPropertiesForKeys: getEnumeratorResourceKeys(),
		options: [
			.skipsHiddenFiles,
			.producesRelativePathURLs
		],
		errorHandler: { url, error in
			return true // continue on error
		}
	)
}

@MainActor
func fetchAudiobooks(dataStore: DataStore) throws {
	if !canAccessURL() {
		throw NSError(domain: "cannot access url", code: 0, userInfo: nil)
	}

	guard let url = Settings.shared.url else {
		throw NSError(domain: "cannot read url", code: 0, userInfo: nil)
	}

	Task {
		let needsStopAccessingSecurity = url.startAccessingSecurityScopedResource()
		defer {
			if needsStopAccessingSecurity {
				url.stopAccessingSecurityScopedResource()
			}
		}

		guard let enumerator = getEnumerator(for: url) else {
			throw NSError(domain: "cannot create enumerator", code: 0, userInfo: nil)
		}

		var directoryMap: [String:Audiobook] = [:]
		var insertMap: [Audiobook:Bool] = [:]

		for case let u as URL in enumerator {
			let enumURL = u.isFileURL ? u : url.appendingPathComponent(u.relativePath)
			let resourceValues = try? enumURL.resourceValues(forKeys: Set(getEnumeratorResourceKeys()))

			if resourceValues?.isDirectory ?? false {
				let audiobook = Audiobook(url: enumURL)
				directoryMap[enumURL.standardized.path] = audiobook
				insertMap[audiobook] = false
				continue
			}

			if !["m4a", "m4b", "mp3", "gif", "jpg", "jpeg", "png"].contains(enumURL.pathExtension) {
				continue
			}
			let data = (
				url.appendingPathComponent(u.relativePath),
				resourceValues?.totalFileSize ?? 0,
				resourceValues?.contentModificationDate ?? Date()
			)

			let path = enumURL.deletingLastPathComponent().standardized.path
			guard let audiobook = directoryMap[path] else {
				print("audiobook not found in directoryMap for \(u.relativePath)")
				return
			}
			guard let isInserted = insertMap[audiobook] else {
				print("insert state not found in insertMap for \(u.relativePath)")
				return
			}
			if !isInserted {
				do {
					try await dataStore.insertAudiobook(audiobook: audiobook)
				} catch {
					print("insert audiobook error: \(error)")
					continue
				}
				insertMap[audiobook] = true
			}
			let file = File(
				url: data.0,
				size: data.1,
				mod: data.2
			)
			file.audiobook = audiobook
			await fetchMetadata(from: file)

			if audiobook.files == nil {
				audiobook.files = []
			}
			audiobook.files?.append(file)

			do {
				try await dataStore.insertFile(file: file)
			} catch {
				print("insert file error: \(error)")
				continue
			}

			do {
				try await dataStore.save()
			} catch {
				print("insert file error: \(error)")
				continue
			}
		}
	}
}

func fetchMetadata(from file: File) async {
	let asset = AVURLAsset(url: file.url)
	var metadata: [AVMetadataItem] = []
	do {
		metadata = try await asset.load(.metadata)
	} catch {
		print("Util: cannot load metadata: \(error)")
		return
	}

	do {
		let duration = try await asset.load(.duration)
		file.duration = CMTimeGetSeconds(duration)
	} catch {
		print("Util: cannot load asset duration: \(error)")
	}

	for item in metadata {
		guard let key = item.commonKey?.rawValue else { continue }
		do {
			switch key {
				case AVMetadataKey.commonKeyTitle.rawValue:
					file.title = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyArtist.rawValue:
					file.artist = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyAlbumName.rawValue:
					file.album = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyArtwork.rawValue:
					file.cover = try await item.load(.dataValue)
				default:
					break
			}
		} catch {
			print("Util: cannot load asset metadata: \(error)")
			continue
		}
	}
}

func relativeDateString(from date: String?) -> String {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z" // Matches Date.description format
	guard let dateString = date, let date = formatter.date(from: dateString) else {
		return "Never Updated"
	}

	let timeInterval = Date().timeIntervalSince(date)
	if timeInterval < 60 {
		return "Just Now"
	}

	let relativeFormatter = RelativeDateTimeFormatter()
	relativeFormatter.unitsStyle = .full
	return "Updated \(relativeFormatter.localizedString(for: date, relativeTo: Date()))"
}
