//
//  Models.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import Foundation
import SwiftData

@Model
final class File: Hashable {
	@Attribute(.unique)
	var id: String
	var url: URL
	var name: String
	var ext: String
	var size: Int
	var added: Date
	var mod: Date
	var data: Data?
	var title: String?
	var artist: String?
	var author: String?
	var album: String?
	var artwork: Data?
	var duration: Double = 0 // seconds
	@Relationship(inverse: \Audiobook.files)
	var audiobook: Audiobook?

	init(url: URL, size: Int, mod: Date) {
		self.url = url
		self.id = url.standardized.absoluteString
		self.name = url.lastPathComponent
		self.ext = url.standardized.pathExtension
		self.size = size
		self.mod = mod
		self.added = Date()
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
