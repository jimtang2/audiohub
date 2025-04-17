//
//  Views.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI
import SwiftData

struct RootView: View {
	@Environment(\.modelContext) var context: ModelContext

	@Query var settings: [Settings]

	var body: some View {
		NavigationStack {

		}
		.onAppear(perform: onAppear)
	}

	func onAppear() {
		// check existence of a network location

		// check its availability (reachable + security scope)
		// 
		guard let settings = settings.first else {
			let newSettings = Settings()
			modelContext.insert(newSettings)
		}
		// If no settings exist, create and insert one
		return newSettings
	}
}
