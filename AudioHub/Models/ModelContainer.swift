//
//  ModelContainer.swift
//  AudioHub
//
//  Created by Jimmy Tang on 20/4/2025.
//

import SwiftData

extension ModelContainer {
	static var shared: ModelContainer = {
		let schema = Schema([
			Audiobook.self,
			File.self
		])

		do {
			return try ModelContainer(
				for: schema,
				configurations: [
					ModelConfiguration(
						schema: schema,
						isStoredInMemoryOnly: false
					)
				]
			)
		} catch {
			fatalError("Could not create ModelContainer: \(error)")
		}
	}()
}
