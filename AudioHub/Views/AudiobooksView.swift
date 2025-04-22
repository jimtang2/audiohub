//
//  AudiobooksView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 17/4/2025.
//

import SwiftUI
import SwiftData

struct AudiobooksView: View {
	@Environment(\.isSearching) private var isSearching

	@Binding var presentSheet: Bool
	@Binding var presentFileImporter: Bool
	@Binding var isWorking: Bool
	@Binding var sortValue: String
	@Binding var searchText: String
	@Binding var task: Task<Void, Never>?

	var refresh: () -> Void

	@State private var columns = Array(repeating: GridItem(.flexible()), count: 2)

	@Query(sort: \Audiobook.mod, order: .reverse, animation: .default)
	private var audiobooks: [Audiobook]

	var filteredAudiobooks: [Audiobook] {
		if searchText.isEmpty {
			return []
		} else {
			return audiobooks.filter { [$0.title ?? "", $0.author ?? "", $0.artist ?? "", $0.album ?? ""].joined(separator: " ").lowercased().contains(searchText.lowercased()) }
		}
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 0){
				if !isSearching {
					HorizontalLine()
					ScrollViewItem {
						Text("text")
							.navigationTitle("Downloaded")
					} label: {
						Image(systemName: "arrow.down.circle")
							.font(.system(size: 20))
							.foregroundColor(.accentColor)
						Text("Downloaded")
					}
					HorizontalLine()

					Text("\(audiobooks.count > 0 ? "\(audiobooks.count)" : "No") audiobook\(audiobooks.count > 1 ? "s" : "")")
						.padding(EdgeInsets(top: 10, leading: 50, bottom: 5, trailing: 20))
						.foregroundStyle(.secondary)

					Text(isWorking ? "Updating..." : relativeDateString(from: Settings.shared.lastUpdated))
						.padding(EdgeInsets(top: 5, leading: 50, bottom: 10, trailing: 20))
						.foregroundStyle(.secondary)

					LazyVGrid(columns: columns, alignment: .center, spacing: 80) {
						ForEach(audiobooks, id: \.self) { audiobook in
							GridItemView(audiobook)
						}
					}
					.padding(EdgeInsets(
						top: 80,
						leading: 20,
						bottom: 80,
						trailing: 20
					))

				} else {
					LazyVStack {
						if filteredAudiobooks.count == 0 {
							Text("No matching audiobooks found.")
						} else {
							ForEach(filteredAudiobooks, id: \.self) { audiobook in
								ListItemView(audiobook: audiobook)
							}
						}
					}
				}
			}
		}
		.refreshable { refresh() }
	}

	func relativeDateString(from date: String?) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z" // Matches Date.description format
		guard let dateString = date, let date = formatter.date(from: dateString) else {
			return "Never Updated"
		}

		let timeInterval = Date().timeIntervalSince(date)
		if timeInterval < 60 {
			return "Just Now"
		}

		let relativeFormatter = RelativeDateTimeFormatter()
		relativeFormatter.unitsStyle = .full
		return "Updated \(relativeFormatter.localizedString(for: date, relativeTo: Date()))"
	}
}

struct GridItemView: View {
	@State var imageData: Data?
	@State var title: String
	@State var author: String?

	var audiobook: Audiobook

	var body: some View {
		VStack {
			ZStack {
				NavigationLink(
					destination: AudiobookDetailsView(audiobook),
					label: {
						if let data = imageData, !data.isEmpty, let uiImage = UIImage(data: data) {
							Image(uiImage: uiImage)
								.resizable()
								.scaledToFit()
								.frame(maxWidth: .infinity, maxHeight: .infinity)
						} else {
							Text("\(title) - \(author ?? "Unknown")")
								.multilineTextAlignment(.center)
								.padding()
								.foregroundColor(.white)
								.bold()
						}
					}
				)
			}
			.frame(width: 160, height: 160)
			.background(Color(red: 0.2, green: 0.2, blue: 0.2))
			.cornerRadius(4)

			VStack(alignment: .leading) {
				Text(title)
					.foregroundStyle(.primary)
					.frame(maxWidth: .infinity, alignment: .leading)
				Text(author ?? "")
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
				Spacer()
			}
			.frame(width: 160, height: 60)
		}
	}

	init(_ audiobook: Audiobook) {
		self.audiobook = audiobook
		self._title = State(initialValue: audiobook.title ?? audiobook.album ?? audiobook.url.lastPathComponent)
		self._author = State(initialValue: audiobook.author ?? audiobook.artist)
		self._imageData = State(initialValue: audiobook.artwork ?? audiobook.files.first { $0.data != nil }?.data)
	}
}

struct ListItemView: View {
	var audiobook: Audiobook

	var body: some View {
		ScrollViewItem {
			AudiobookDetailsView(audiobook)
				.navigationTitle(audiobook.url.lastPathComponent)
		} label: {
			Text(audiobook.url.lastPathComponent)
		}

		HorizontalLine()
	}
}

struct ScrollViewItem<Destination: View, Label: View>: View {
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
			.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
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
		.padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 20))
	}
}

#Preview {
	@Previewable @State var presentSheet: Bool = false
	@Previewable @State var presentFileImporter: Bool = false
	@Previewable @State var shouldRefresh: Bool = false
	@Previewable @State var isWorking: Bool = false
	@Previewable @State var sortValue: String = "Added"
	@Previewable @State var searchText: String = ""
	@Previewable @State var task: Task<Void, Never>?
	let refresh: () -> Void = { }

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
	}
}
