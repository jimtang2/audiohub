//
//  ImportPromptView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 17/4/2025.
//

import SwiftUI

struct TutorialView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var presentFileImporter: Bool
	@State var presentAlert: Bool = false

	var body: some View {
		NavigationStack {
			List {
				HStack {
					Button {
						presentFileImporter = true
						dismiss()
					} label: {
						HStack {
							Text("1️⃣ Browse to audiobook files")
							Spacer()
							Image(systemName: "chevron.right")
						}
					}
				}
				HStack {
					Button {
						presentAlert = true
					} label: {
						HStack {
							Text("2️⃣ Download Watch app in App Store")
							Spacer()
							Image(systemName: "chevron.right")
						}
					}
				}

				Text("3️⃣ Select audiobooks to sync to Apple Watch")
				Text("4️⃣ Enjoy! 🎉🏃‍♂️")
			}
			.background(.background)
			.navigationTitle("Quick Tutorial")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button(action: {
						presentAlert = true
					}, label: {
						Text("Get Watch App")
					})
				}
				ToolbarItem(placement: .topBarLeading) {
					Button(action: {
						dismiss()
					}, label: {
						Text("Done")
							.bold()
					})
				}
			}
			.alert("Watch App Store", isPresented: $presentAlert, actions: {
				Button(role: .none, action: openAppStore, label: {
					Text("Go to App Store")
				})
				Button(role: .cancel, action: {}, label: {
					Text("Cancel")
				})
			}, message: {
				Text("Open App Store now?")
			})
			.padding(EdgeInsets(top: 20, leading: 10, bottom: 0, trailing: 10))
		}
	}

	func openAppStore() {
		let id = Settings.WATCH_APP_ID
		guard let url = URL(string: "https://apps.apple.com/app/id\(id)") else {
			return
		}
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
}

#Preview {
	@Previewable @State var presentFileImporter: Bool = false
	TutorialView(presentFileImporter: $presentFileImporter)
}
