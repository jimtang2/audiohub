//
//  AudiobooksView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 17/4/2025.
//

import SwiftUI
import SwiftData

let SORT_CRITERIA = [
	"Added",
	"Modified",
	"Title",
	"Artist"
]

struct AudiobooksView: View {
	@Environment(\.modelContext) private var modelContext: ModelContext
	@Environment(\.dismiss) private var dismiss
	@Binding var presentSheet: Bool
	@Binding var presentFileImporter: Bool
	@Binding var shouldRefresh: Bool
	@State private var sortCriteria: String = "Added"
	@State private var presentAlert: Bool = false
	@State private var isRefreshing: Bool = false
	@State private var searchText: String = ""
	@State private var dataStore: DataStore = DataStore(modelContainer: ModelContainer.shared)

	var body: some View {
		ScrollView {
			VStack(spacing: 0){
				ContentView(searchText: $searchText)
					.searchable(
						text: $searchText,
						placement: .automatic,
						prompt: "Search audiobooks"
					)
			}
		}

		.refreshable { await refreshFunc() }

		.onChange(of: shouldRefresh) {
			print("should refresh")
			if shouldRefresh {
				Task { await refreshFunc() }
			}
		}

		.toolbar {
			ToolbarItemGroup(placement: .topBarTrailing) {
				if isRefreshing {
					ProgressView()
						.progressViewStyle(.circular)
				}
				Menu {
					Section("Sort By") {
						ForEach(SORT_CRITERIA, id: \.self) { criteria in
							Button(action: { changeSortCriteria(criteria: criteria) }, label: {
								Text(criteria)
								if criteria == sortCriteria {
									Image(systemName: "checkmark")
								}
							})
						}
					}
					NavigationLink(
						destination: {
							SettingsView()
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

		.alert(
			"Connection Refresh",
			isPresented: $presentAlert,
			actions: {
				Button(role: .cancel) {
					dismiss()
				} label: {
					Text("Cancel")
				}
				Button {
					presentFileImporter = true
				} label: {
					Text("Continue")
				}
			},
			message: {
				Text("The connection to the location must be refreshed. Tap Continue to select it.")
			}
		)
	}

	func refreshFunc() async {
		print(0)
		if Settings.shared.url == nil || !canAccessURL() {
			presentAlert = true
			return
		}
		if isRefreshing {
			return
		}
		isRefreshing = true
		defer {
			Settings.shared.lastRefreshDate = Date().description
			isRefreshing = false
		}
		print(2)
		do {
			try fetchAudiobooks(dataStore: dataStore)
		} catch {
			print("\(error)")
		}
	}

	func changeSortCriteria(criteria: String) {

	}
}

struct ContentView: View {
	@Environment(\.isSearching) private var isSearching
	@State private var columns = Array(repeating: GridItem(.flexible()), count: 2)
	@Query private var audiobooks: [Audiobook]
	@Binding var searchText: String

	var filteredAudiobooks: [Audiobook] {
		if searchText.isEmpty {
			return []
		} else {
			return audiobooks.filter { "\($0.title ?? "") \($0.author ?? "" ) \($0.id)".lowercased().contains(searchText.lowercased()) }
		}
	}

	var body: some View {
		if !isSearching {
			HorizontalLine()

			ScrollViewNavigationLink {
				Text("text")
					.navigationTitle("Downloaded")
			} label: {
				Image(systemName: "arrow.down.circle")
					.font(.system(size: 20))
				Text("Downloaded")
			}

			HorizontalLine()

			Text(relativeDateString(from: Settings.shared.lastRefreshDate))

			LazyVGrid(columns: columns, alignment: .center, spacing: 80) {
				ForEach(audiobooks, id: \.self) { audiobook in
					AudiobookGridItemView(audiobook: audiobook)
				}
			}
			.padding(EdgeInsets(top: 80, leading: 20, bottom: 80, trailing: 20))

		} else {
			LazyVStack {
				if filteredAudiobooks.count == 0 {
					Text("No matching audiobooks found.")
				} else {
					ForEach(filteredAudiobooks, id: \.self) { audiobook in
						AudiobookListItemView(audiobook: audiobook)
					}
				}
			}
		}
	}
}

struct AudiobookGridItemView: View {
	var audiobook: Audiobook

	var body: some View {
		ZStack {
			NavigationLink(
				destination: AudiobookDetailsView(audiobook: audiobook),
				label: {
					Text(audiobook.url.lastPathComponent)
				}
			)
		}
		.frame(width: 160, height: 160)
		.background(Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.3))
	}
}

struct AudiobookListItemView: View {
	var audiobook: Audiobook

	var body: some View {
		ScrollViewNavigationLink {
			AudiobookDetailsView(audiobook: audiobook)
				.navigationTitle(audiobook.url.lastPathComponent)
		} label: {
			Text(audiobook.url.lastPathComponent)
		}

		HorizontalLine()
	}
}

struct ScrollViewNavigationLink<Destination: View, Label: View>: View {
	var destination: () -> Destination
	var label: () -> Label

	init(
		@ViewBuilder destination: @escaping () -> Destination,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.destination = destination
		self.label = label
	}

	var body: some View {
		NavigationLink {
			destination()
		} label: {
			HStack{
				label()
				Spacer()
				Image(systemName: "chevron.right")
					.foregroundColor(.secondary)
					.padding(.horizontal, 5)
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 5)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

struct HorizontalLine: View {
	var body: some View {
		ZStack {
			Rectangle()
				.frame(height: 1)
				.frame(maxWidth: .infinity)
				.foregroundColor(Color(UIColor.separator))
				.alignmentGuide(.bottom) { d in d[.bottom] }
		}
		.padding(.horizontal, 20)
	}
}

#Preview {
	@Previewable @State var presentSheet: Bool = false
	@Previewable @State var presentFileImporter: Bool = false
	@Previewable @State var shouldRefresh: Bool = false

	NavigationStack {
		AudiobooksView(
			presentSheet: $presentSheet,
			presentFileImporter: $presentFileImporter,
			shouldRefresh: $shouldRefresh
		)
	}
}
