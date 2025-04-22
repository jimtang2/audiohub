//
//  RootView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI
import SwiftData

struct AppView: View {
	@Environment(\.dismiss) private var dismiss

	@State private var presentAlert: Bool = false
	@State private var presentFileImporter: Bool = false
	@State private var presentSheet: Bool = false
	@State private var presentTutorial: Bool
	@State private var isWorking: Bool = false
	@State private var sortValue: String
	@State private var searchText: String = ""
	@State private var dataStore: DataStore = DataStore(modelContainer: ModelContainer.shared)
	@State private var task: Task<Void, Never>?

	let SORT_VALUES = ["Added", "Modified", "Title", "Artist"]

	init() {
		presentTutorial = Settings.shared.url == nil
		sortValue = Settings.shared.sortValue
	}

	func fileImporterOnCompletion(_ result: Result<URL, Error>) {
		if case .success(let url) = result {
			Settings.shared.url = url
			print(url.path)
			if canAccessURL() {
				try? saveBookmarkData()
			}
			refresh()
		}
	}

	func refresh() {
		if !canAccessURL() {
			presentAlert = true
			return
		}
		do {
			isWorking = true
			try fetchAudiobooks(dataStore: dataStore, task: $task, completion: {
				isWorking = false
				Settings.shared.lastUpdated = Date().description
			})
		} catch {
			print("\(error)")
		}
	}

	var body: some View {
		NavigationStack {
			AudiobooksView(
				presentSheet: $presentSheet,
				presentFileImporter: $presentFileImporter,
				isWorking: $isWorking,
				sortValue: $sortValue,
				searchText: $searchText,
				task: $task,
				refresh: refresh
			)
			.navigationTitle("Audiobooks")
			.sheet(
				isPresented: $presentSheet,
				content: {
					Text("oops")
				}
			)
			.sheet(
				isPresented: $presentTutorial,
				content: {
					TutorialView(presentFileImporter: $presentFileImporter)
				}
			)
			.fileImporter(
				isPresented: $presentFileImporter,
				allowedContentTypes: [.folder],
				onCompletion: fileImporterOnCompletion
			)
			.alert(
				"Connection Refresh",
				isPresented: $presentAlert,
				actions: {
					Button(role: .cancel, action: {
						dismiss()
					}) {
						Text("Cancel")
					}
					Button(role: .none, action: {
						presentFileImporter = true
					}) {
						Text("Continue")
					}
				},
				message: {
					Text("The connection to the location must be refreshed. Tap Continue to select it.")
				}
			)
			.searchable(
				text: $searchText,
				placement: .automatic,
				prompt: "Search"
			)
			.toolbar(content: toolbarContent)
		}
	}

	func toolbarContent() -> some ToolbarContent {
		ToolbarItemGroup(placement: .topBarTrailing) {
			if isWorking {
				ProgressView()
					.progressViewStyle(.circular)
			}
			Menu {
				Section("Sort By") {
					ForEach(SORT_VALUES, id: \.self) { value in
						Button(action: {
							Settings.shared.sortValue = value
							sortValue = value
						}, label: {
							Text(value)
							if value == sortValue {
								Image(systemName: "checkmark")
							}
						})
					}
				}

				NavigationLink(
					destination: {
						SettingsView(
							presentTutorial: $presentTutorial
						)
						.navigationTitle("Settings")
					},
					label: {
						Text("Settings")
						Image(systemName: "gearshape")
					}
				)
			} label: {
				Image(systemName: "ellipsis")
			}
		}
	}
}

#Preview {
	AppView()
}
