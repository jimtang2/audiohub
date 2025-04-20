//
//  DataStore.swift
//  AudioHub
//
//  Created by Jimmy Tang on 20/4/2025.
//

import Foundation
import SwiftData

@ModelActor
actor DataStore {
	func insertAudiobook(audiobook: Audiobook) throws {
		let id = audiobook.url.standardized.absoluteString
		let descriptor = FetchDescriptor<Audiobook>(
			predicate: #Predicate<Audiobook> { $0.id == id }
		)
		if let existing = try modelContext.fetch(descriptor).first {
			if let title = audiobook.title { existing.title = title }
			if let author = audiobook.author { existing.author = author }
			try modelContext.save()
			return
		}
		modelContext.insert(audiobook)
	}

	func insertFile(file: File) throws {
		let id = file.url.standardized.absoluteString
		let descriptor = FetchDescriptor<File>(
			predicate: #Predicate<File> { $0.id == id }
		)
		if let existing = try modelContext.fetch(descriptor).first {
			// Update only non-nil properties to avoid overwriting with nil
			existing.size = file.size
			existing.mod = file.mod
			existing.name = file.name
			if let title = file.title { existing.title = title }
			if let artist = file.artist { existing.artist = artist }
			if let album = file.album { existing.album = album }
			existing.duration = file.duration // Always update, as 0 is valid
			if let cover = file.cover { existing.cover = cover }
			try modelContext.save()
			return
		}
		modelContext.insert(file)
	}

	func save() throws {
		try modelContext.save()
	}
}


