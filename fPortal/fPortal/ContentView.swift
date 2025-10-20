//
//  ContentView.swift
//  fPortal
//
//  Created by Hugo Joncour on 2025-10-19.
//

import SwiftUI

struct ContentView: View {
    @State private var enableSync = true
    @State private var showBadges = true
    @State private var autoStart = false
    @State private var notificationsEnabled = true
    @State private var selectedSyncFolder = "/Users/Shared/MySyncExtension Documents"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "folder.badge.gearshape")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 32))
                Text("fPortal Settings")
                    .font(.title)
                    .bold()
            }
            .padding(.bottom, 20)
            
            Divider()
                .padding(.bottom, 20)
            
            // Settings List
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // General Settings Section
                    SettingsSection(title: "General", icon: "gear") {
                        SettingRow(icon: "arrow.triangle.2.circlepath", title: "Enable Sync") {
                            Toggle("", isOn: $enableSync)
                                .labelsHidden()
                        }
                        
                        SettingRow(icon: "bell.badge", title: "Notifications") {
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                        }
                        
                        SettingRow(icon: "power", title: "Auto-start at login") {
                            Toggle("", isOn: $autoStart)
                                .labelsHidden()
                        }
                    }
                    
                    // Finder Integration Section
                    SettingsSection(title: "Finder Integration", icon: "folder") {
                        SettingRow(icon: "tag", title: "Show badge overlays") {
                            Toggle("", isOn: $showBadges)
                                .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Sync Folder")
                                    .fontWeight(.medium)
                            }
                            Text(selectedSyncFolder)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Features Section
                    SettingsSection(title: "Features", icon: "star.fill") {
                        FeatureItem(
                            title: "Real-time sync monitoring",
                            description: "Track file changes instantly"
                        )
                        FeatureItem(
                            title: "Custom badge indicators",
                            description: "Visual status for your files"
                        )
                        FeatureItem(
                            title: "Context menu integration",
                            description: "Quick actions in Finder"
                        )
                        FeatureItem(
                            title: "Toolbar icon access",
                            description: "Easy access from Finder toolbar"
                        )
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Version:")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
        }
        .padding(30)
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let control: Content
    
    init(icon: String, title: String, @ViewBuilder control: () -> Content) {
        self.icon = icon
        self.title = title
        self.control = control()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(title)
                .fontWeight(.medium)
            Spacer()
            control
        }
        .padding(.vertical, 4)
    }
}

struct FeatureItem: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.accentColor)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
