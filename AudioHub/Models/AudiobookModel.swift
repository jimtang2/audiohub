//
//  Audiobook.swift
//  AudioHub
//
//  Created by Jimmy Tang on 20/4/2025.
//

//
//  Models.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import Foundation
import SwiftData

@Model
final class Audiobook: Hashable, Identifiable {
	@Attribute(.unique)
	var id: String
	var url: URL
	var title: String?
	var artist: String?
	var author: String?
	var album: String?
	var artwork: Data?
	var added: Date
	var mod: Date
	var lastScanned: Date?
	@Relationship
	var files: [File]

	init(url: URL) {
		self.url = url
		self.id = url.standardized.absoluteString
		self.added = Date()
		self.mod = Date.distantPast
		self.files = []
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}

