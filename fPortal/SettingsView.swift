import SwiftUI

private let appGroupId = "group.com.hjoncour.fPortal"
private let preferredBundleKey = "preferredBundleID"

struct SettingsView: View {
	@AppStorage(preferredBundleKey, store: UserDefaults(suiteName: appGroupId))
	private var preferredBundleID: String = "com.microsoft.VSCode"

	var body: some View {
		Form {
			Section(header: Text("Preferred App")) {
				TextField("Bundle Identifier", text: $preferredBundleID)
					.textFieldStyle(.roundedBorder)
					.font(.system(.body, design: .monospaced))
				Text("Examples: com.microsoft.VSCode, com.apple.Terminal, com.googlecode.iterm2")
					.font(.footnote)
					.foregroundStyle(.secondary)
				HStack {
					Spacer()
					Button("Reset to VS Code") {
						preferredBundleID = "com.microsoft.VSCode"
					}
				}
			}
			Section(header: Text("Notes")) {
				Text("The Finder extension monitors your Home folder by default. See README to add more roots if desired.")
					.font(.footnote)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(20)
		.frame(minWidth: 520)
	}
}
