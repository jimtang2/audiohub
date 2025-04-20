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
	var size: Int
	var mod: Date
	var title: String?
	var artist: String?
	var album: String?
	var duration: Double = 0 // seconds
	var cover: Data?
	@Relationship(inverse: \Audiobook.files)
	var audiobook: Audiobook?

	init(url: URL, size: Int, mod: Date) {
		self.url = url
		self.id = url.standardized.absoluteString
		self.name = url.lastPathComponent
		self.size = size
		self.mod = mod
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
