//
//  Util.swift
//  AudioHub
//
//  Created by Jimmy Tang on 18/4/2025.
//

import AVFoundation
import SwiftData
import SwiftUI
import CryptoKit

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

func getEnumerator(for url: URL) -> FileManager.DirectoryEnumerator? {
	return FileManager.default.enumerator(
		at: url,
		includingPropertiesForKeys: [
			.isDirectoryKey,
			.nameKey,
			.totalFileSizeKey,
			.contentModificationDateKey
		],
		options: [
			.skipsHiddenFiles,
			.producesRelativePathURLs
		],
		errorHandler: { url, error in
			return true // continue on error
		}
	)
}

func fetchAudiobooks(dataStore: DataStore, task: Binding<Task<Void, Never>?>, completion: @escaping () async -> Void) throws {
	guard let baseURL = Settings.shared.url else {
		throw NSError(domain: "cannot read url", code: 0, userInfo: nil)
	}

	task.wrappedValue?.cancel()

	task.wrappedValue = Task {
		let needsStopAccessingSecurity = baseURL.startAccessingSecurityScopedResource()
		defer {
			if needsStopAccessingSecurity {
				baseURL.stopAccessingSecurityScopedResource()
			}
		}

		guard let enumerator = getEnumerator(for: baseURL) else {
			return
		}

		var audiobooksMap: [String:Audiobook] = [:]
		var insertedAudiobooks: [Audiobook:Bool] = [:]

		for case let enumURL as URL in enumerator {
			var url: URL

			if enumURL.isFileURL {
				url = enumURL
			} else {
				url = baseURL.appendingPathComponent(enumURL.relativePath)
			}

			let resourceValues = try? url.resourceValues(forKeys: [
				.isDirectoryKey,
				.nameKey,
				.totalFileSizeKey,
				.contentModificationDateKey
			])

			guard let isDir = resourceValues?.isDirectory else {
				continue
			}

			var audiobook: Audiobook

			if isDir {
				audiobook = Audiobook(url: url)
				audiobooksMap[url.standardized.path] = audiobook
				insertedAudiobooks[audiobook] = false
				continue
			}

			guard let audiobook = audiobooksMap[url.deletingLastPathComponent().standardized.path] else {
				print("did not create audiobook for \(enumURL.relativePath)")
				continue
			}

			guard let isAudiobookInserted = insertedAudiobooks[audiobook] else {
				print("did not mark audiobook insertion state for \(enumURL.relativePath)")
				continue
			}

			let fileExt = url.pathExtension
			var isMediaFile: Bool

			switch fileExt {
				case "m4a", "m4b", "mp3":
					isMediaFile = true
					break
				case "gif", "jpg", "jpeg", "png":
					isMediaFile = false
					break
				default:
					continue
			}

			guard let size = resourceValues?.totalFileSize else {
				continue
			}

			guard let mod = resourceValues?.contentModificationDate else {
				continue
			}

			if !isAudiobookInserted {
				do {
					try await dataStore.insertAudiobook(audiobook: audiobook)
					insertedAudiobooks[audiobook] = true
				} catch {
					print("insert audiobook error: \(error)")
					continue
				}
			}

			let file = File(url: url, size: size, mod: mod)
			file.audiobook = audiobook

			if isMediaFile {
				await fetchMetadata(from: file)
			} else {
				await fetchData(from: file)
			}

			audiobook.files.append(file)

			do {
				try await dataStore.insertFile(file: file)
			} catch {
				print("insert file error: \(error)")
				continue
			}

			if file.mod > audiobook.mod {
				audiobook.mod = file.mod
			}

			if audiobook.title == nil && file.title != nil {
				audiobook.title = file.title
			}

			if audiobook.album == nil && file.album != nil {
				audiobook.album = file.album
			}

			if audiobook.author == nil && file.author != nil {
				audiobook.author = file.author
			}

			if audiobook.artist == nil && file.artist != nil {
				audiobook.artist = file.artist
			}

			if audiobook.artwork == nil && file.artwork != nil {
				audiobook.artwork = file.artwork
			}

			do {
				try await dataStore.save()
			} catch {
				print("insert file error: \(error)")
				continue
			}
		}
		await completion()
	}
}

func fetchMetadata(from file: File) async {
	let asset = AVURLAsset(url: file.url)
	var metadata: [AVMetadataItem] = []

	do {
		metadata = try await asset.load(.metadata)
	} catch {
		return
	}

	do {
		let duration = try await asset.load(.duration)
		file.duration = CMTimeGetSeconds(duration)
	} catch {
		print("Util: cannot load asset duration: \(error)")
	}

	for item in metadata {
		guard let key = item.commonKey?.rawValue else {
			continue
		}
		do {
			switch key {
				case AVMetadataKey.commonKeyTitle.rawValue:
					file.title = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyArtist.rawValue:
					file.artist = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyAuthor.rawValue:
					file.author = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyAlbumName.rawValue:
					file.album = try await item.load(.stringValue)
				case AVMetadataKey.commonKeyArtwork.rawValue:
					file.artwork = try await item.load(.dataValue)
				default:
					break
			}
		} catch {
			continue
		}
	}
}

func fetchData(from file: File) async {
	guard let data = try? Data(contentsOf: file.url) else {
		return
	}
	file.data = data
}

func hashURLPath(_ url: URL) -> String {
	let path = url.path
	let inputData = Data(path.utf8)
	let hash = SHA256.hash(data: inputData)
	return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func writeData(_ data: Data, toFileNamed fileName: String) throws {
	let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		.appendingPathComponent(fileName)
	try data.write(to: url)
}

func readData(fromFileNamed fileName: String) throws -> Data {
	let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		.appendingPathComponent(fileName)
	return try Data(contentsOf: url)
}
