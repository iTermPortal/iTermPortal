import SwiftUI

@main
struct OpenInAppApp: App {
	var body: some Scene {
		WindowGroup {
			VStack(alignment: .leading, spacing: 12) {
				Text("OpenInApp")
					.font(.title)
				Text("This host app provides settings for the Finder Sync extension that adds a “Code” toolbar button in Finder. Use Settings to choose your preferred app’s bundle identifier.")
				Link("Project README", destination: URL(string: "https://example.invalid/OpenInApp-README")!)
			}
			.padding(24)
			.frame(minWidth: 520, minHeight: 220, alignment: .topLeading)
		}
		Settings {
			SettingsView()
		}
	}
}