//
//  AudioHubApp.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI
import SwiftData

@main
struct AudioHubApp: App {
    var body: some Scene {
        WindowGroup {
			  AppContainerView()
        }
		  .modelContainer(ModelContainer.shared)
    }
}

class Settings: ObservableObject {
	static let shared = Settings()

	@AppStorage("url") var url: URL?
	@AppStorage("bookmarkData") var bookmarkData: Data?
	@AppStorage("lastRefresh") var lastRefreshDate: String?
}
