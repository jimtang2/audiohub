//
//  AudiobookDetailsView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 20/4/2025.
//

import SwiftUI

struct AudiobookDetailsView: View {
	var audiobook: Audiobook

	@State private var imageData: Data?
	@State private var title: String
	@State private var author: String?

	init(_ audiobook: Audiobook) {
		self.audiobook = audiobook
		self._title = State(initialValue: audiobook.title ?? audiobook.album ?? audiobook.url.lastPathComponent)
		self._author = State(initialValue: audiobook.author ?? audiobook.artist)
		self._imageData = State(initialValue: audiobook.artwork ?? audiobook.files.first { $0.data != nil }?.data)
	}

	var body: some View {
		VStack(alignment: .center) {
			ZStack {
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
			Text(title)
			Text(author ?? "author")
			Spacer()
		}
	}
}

#Preview {
	let audiobook = Audiobook(url: URL(fileURLWithPath: "/", isDirectory: true))

	AudiobookDetailsView(audiobook)
		.modelContainer(PreviewData().container)
}
