//
//  ImportPromptView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 17/4/2025.
//

import SwiftUI

struct WelcomeView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var presentFileImporter: Bool

	var body: some View {
		VStack(spacing: 10) {
			Text("Welcome to AudioHub!")
				.bold()
				.font(.title2)
			Text("To get started, please select the location of your audiobooks files.")
				.multilineTextAlignment(.center)
			Button {
				presentFileImporter = true
				dismiss()
			} label: {
				Text("Browse")
				Image(systemName: "chevron.right")
			}
			.padding(.vertical, 15)
		}
		.padding(.horizontal, 15)
	}
}

#Preview {
	@Previewable @State var presentFileImporter: Bool = false
	WelcomeView(presentFileImporter: $presentFileImporter)
}
