//
//  Item.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import Foundation
import SwiftData

@Model
final class Settings {
	var url: URL?
	var bookmarkData: Data?

	init() {
		self.url = nil
		self.bookmarkData = nil
	}
}

@Model
final class File {
	var name: String
	var url: URL
	var path: String
	var isDir: Bool
	var metadata: Metadata?

	init(name: String, url: URL, path: String, isDir: Bool, metadata: Metadata? = nil) {
		self.name = name
		self.url = url
		self.path = path
		self.isDir = isDir
		self.metadata = metadata
	}
}

@Model
final class Metadata {
	var title: String
	var artist: String
	var album: String
	var cover: Data?

	init(title: String, artist: String, album: String, cover: Data? = nil) {
		self.title = title
		self.artist = artist
		self.album = album
		self.cover = cover
	}
}
