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
final class Audiobook: Hashable {
	@Attribute(.unique)
	var id: String
	var url: URL
	var title: String?
	var author: String?
	@Relationship
	var files: [File]?

	init(url: URL) {
		self.url = url
		self.id = url.standardized.absoluteString
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}

