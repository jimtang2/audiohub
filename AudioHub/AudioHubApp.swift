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
			  AppView()
        }
		  .modelContainer(ModelContainer.shared)
    }
}

class Settings: ObservableObject {
	static let shared = Settings()
	static let WATCH_APP_ID: String = "1541434437"

	@AppStorage("url") var url: URL?
	@AppStorage("bookmarkData") var bookmarkData: Data?
	@AppStorage("lastRefresh") var lastUpdated: String?
	@AppStorage("sortValue") var sortValue: String = "Added"
	@AppStorage("autoSync") var autoSync: Bool = true
	@AppStorage("useiCloud") var useiCloud: Bool = true

}
