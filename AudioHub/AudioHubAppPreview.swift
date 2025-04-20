//
//  PreviewData.swift
//  AudioHub
//
//  Created by Jimmy Tang on 18/4/2025.
//

import Foundation
import SwiftData

class PreviewData {
	var context: ModelContext
	var container: ModelContainer

	@MainActor
	init() {
		let schema = Schema([
			Audiobook.self,
			File.self
		])
		self.container = try! ModelContainer(
			for: schema,
			configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
		)
		self.context = self.container.mainContext
	}
}
