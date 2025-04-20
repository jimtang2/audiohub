//
//  RootView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 14/4/2025.
//

import SwiftUI
import SwiftData

struct AppContainerView: View {
	@Environment(\.modelContext) var context: ModelContext
	@State private var presentSheet: Bool = false
	@State private var presentFileImporter: Bool = false
	@State private var shouldRefresh: Bool = false

	var body: some View {
		NavigationStack {
			AudiobooksView(
				presentSheet: $presentSheet,
				presentFileImporter: $presentFileImporter,
				shouldRefresh: $shouldRefresh
			)
			.navigationTitle("Audiobooks")
			.sheet(
				isPresented: $presentSheet,
				content: sheetContent
			)
			.fileImporter(
				isPresented: $presentFileImporter,
				allowedContentTypes: [.folder],
				onCompletion: fileImporterOnCompletion
			)
		}
		.onAppear(perform: onAppear)
		
	}

	func onAppear() {
		guard let url = Settings.shared.url else {
			presentSheet = true
			return
		}
		print("RootView.onAppear: url = \(url.absoluteString)")
	}

	func fileImporterOnCompletion(_ result: Result<URL, Error>) {
		if case .success(let url) = result {
			Settings.shared.url = url
			if canAccessURL() {
				try? saveBookmarkData()
			}
			shouldRefresh = true
		}
	}

	func sheetContent() -> some View {
		ZStack {
		  if isFirstLaunch() {
			  WelcomeView(presentFileImporter: $presentFileImporter)
		  }
		}
	}
}

#Preview {
	AppContainerView()
}
