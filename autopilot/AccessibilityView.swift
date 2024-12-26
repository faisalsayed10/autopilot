import SwiftUI

struct ApplicationTreeView: View {
    let application: ApplicationInfo
    let level: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(String(repeating: "    ", count: level))
                VStack(alignment: .leading) {
                    HStack {
                        Text(application.name)
                            .fontWeight(level == 0 ? .bold : .regular)
                        if let subrole = application.subrole {
                            Text("(\(subrole))")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Group {
                        if let value = application.value {
                            Text("Value: \(value)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if let frame = application.frame {
                            Text("Frame: \(frame)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Text("Role: \(application.role)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ForEach(application.children) { child in
                ApplicationTreeView(application: child, level: level + 1)
            }
        }
    }
}

struct AccessibilityView: View {
    @StateObject private var accessibilityManager = AccessibilityManager()
    @State private var searchText = ""
    
    var filteredApplications: [ApplicationInfo] {
        if searchText.isEmpty {
            return accessibilityManager.applications
        }
        return accessibilityManager.applications.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.role.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            Text("Accessibility Inspector")
                .font(.title)
                .padding()
            
            HStack {
                Button("Open YouTube") {
                    accessibilityManager.openYouTubeInBrowser()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Send WhatsApp Message") {
                    accessibilityManager.sendWhatsAppMessage()
                }
                .buttonStyle(.borderedProminent)
                
                Divider()
                
                TextField("Search applications...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(filteredApplications) { app in
                        ApplicationTreeView(application: app, level: 0)
                    }
                }
                .padding()
            }
            
            HStack {
                Button("Refresh") {
                    accessibilityManager.refreshApplications()
                }
                .keyboardShortcut("r")
                
                Text("Press ⌘R to refresh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 800)
        .onAppear {
            accessibilityManager.requestAccessibilityPermission()
            accessibilityManager.refreshApplications()
        }
    }
} 