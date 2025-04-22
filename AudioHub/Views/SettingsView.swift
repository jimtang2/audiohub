//
//  SettingsView.swift
//  AudioHub
//
//  Created by Jimmy Tang on 20/4/2025.
//

import SwiftUI

struct SettingsView: View {
	@Binding var presentTutorial: Bool

	@State var autoSync: Bool = Settings.shared.autoSync
	@State var useiCloud: Bool = Settings.shared.useiCloud
//	@State var presentAlert: Bool = false

	var body: some View {
		List {
			Section() {
				Toggle(isOn: $autoSync, label: {
					Text("Automatically sync to Apple Watch")
				})

				Toggle(isOn: $useiCloud, label: {
					Text("Sync with iCloud across devices")
				})

			}
			Section() {
				Button("Show Tutorial") {
					presentTutorial = true
				}
				Button("Send Feedback") {

				}
				Button("Report an issue") {

				}
			}
//			Section() {
//				Button(role: .destructive, action: {
//					presentAlert = true
//				}, label: {
//					Text("Clear All Data")
//				})
//			}
			Section {
				Text("Developed by Lab9.studio, 2025")
					.listRowBackground(Color.clear)
					.listRowInsets(EdgeInsets())
					.foregroundStyle(.secondary)
					.font(.system(size: 13))
					.padding(.horizontal, 10)
			}
		}
//		.alert("Clear All Data",
//			isPresented: $presentAlert,
//			actions: {
//				Button(
//					role: .destructive,
//					action: {
//						presentAlert = false
//					},
//					label: {
//						Text("Clear All Data")
//					}
//				)
//			}, message: {
//				Text("This will remove all cache and downloaded data. Are you sure?")
//			}
//		)
	}
}

#Preview {
	@Previewable @State var presentTutorial: Bool = false
	SettingsView(presentTutorial: $presentTutorial)
}
