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
			if existing.mod < audiobook.mod {
				existing.mod = audiobook.mod
				existing.title = audiobook.title
				existing.artist = audiobook.artist
				existing.author = audiobook.author
				existing.album = audiobook.album
				existing.artwork = audiobook.artwork
			}
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
			if existing.mod < file.mod {
				existing.size = file.size
				existing.mod = file.mod
				existing.name = file.name
				existing.duration = file.duration
				existing.title = file.title
				existing.artist = file.artist
				existing.author = file.author
				existing.album = file.album
				existing.artwork = file.artwork
				existing.data = file.data
			}
			return
		}
		modelContext.insert(file)
	}

	func save() throws {
		try modelContext.save()
	}
}


