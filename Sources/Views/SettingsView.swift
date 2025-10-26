import SwiftUI
import UserNotifications
import AppKit

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var projectStore: ProjectStore
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
            
            // AISettingsView()
            //     .tabItem {
            //         Label("AI", systemImage: "sparkles")
            //     }
            
            FoldersSettingsView()
                .tabItem {
                    Label("Folders", systemImage: "folder")
                }
        }
        .frame(width: 600, height: 450)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section {
                Picker("Motivation Style", selection: $settingsManager.settings.motivationStyle) {
                    ForEach(MotivationStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                
                Text(settingsManager.settings.motivationStyle.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Personality")
                    .font(.headline)
            }
            
            Section {
                LabeledContent("App Version") {
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Button("Reset Onboarding") {
                    settingsManager.settings.hasCompletedOnboarding = false
                    NSApplication.shared.keyWindow?.close()
                }
            } header: {
                Text("About")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var notificationStatus: String = "Checking..."

    var body: some View {
        Form {
            Section {
                Stepper(
                    "Nudge Frequency: \(settingsManager.settings.nudgeFrequencyHours)h",
                    value: $settingsManager.settings.nudgeFrequencyHours,
                    in: 1...168
                )
                
                Text("How often should Momentum remind you about inactive projects")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Frequency")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    Text("Start")
                    Spacer()
                    Picker("", selection: $settingsManager.settings.quietHoursStart) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
                
                HStack {
                    Text("End")
                    Spacer()
                    Picker("", selection: $settingsManager.settings.quietHoursEnd) {
                        ForEach(0..<24) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                }
                
                Text("Momentum won't send notifications during these hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Quiet Hours")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notification Status")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(notificationStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Test Notification") {
                        testNotification()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            checkNotificationStatus()
        }
    }

    var notificationStatusText: String {
        if Bundle.main.bundleIdentifier == nil {
            return "No bundle identifier - notifications may not work"
        }

        // Check if we have a proper bundle URL (not in DerivedData)
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            return "Building in Xcode - notifications may not work properly"
        }

        return notificationStatus
    }

    private func checkNotificationStatus() {
        // Skip status check if running in DerivedData (Xcode build)
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            notificationStatus = "Building in Xcode - status unavailable"
            return
        }

        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "✅ Authorized"
                case .denied:
                    notificationStatus = "❌ Denied by user"
                case .notDetermined:
                    notificationStatus = "⏳ Not requested yet"
                case .provisional:
                    notificationStatus = "⚠️ Provisional"
                case .ephemeral:
                    notificationStatus = "⚠️ Ephemeral"
                @unknown default:
                    notificationStatus = "❓ Unknown status"
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    private func testNotification() {
        print("🔔 Test notification triggered")

        // Check if running in Xcode DerivedData
        if Bundle.main.bundleURL.path.contains("DerivedData") {
            print("⚠️ Running in Xcode - system notifications won't work")
            print("💡 The alert should appear shortly as a fallback")

            // Show immediate feedback for Xcode builds
            let alert = NSAlert()
            alert.messageText = "Test Notification (Xcode Mode)"
            alert.informativeText = "System notifications don't work when running in Xcode. This alert is shown as a fallback."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()

            return
        }

        // Check bundle identifier first
        if let bundleId = Bundle.main.bundleIdentifier {
            print("✅ Bundle identifier found: \(bundleId)")
        } else {
            print("❌ No bundle identifier - notifications may not work")
            print("💡 Try building and running from Xcode with proper entitlements")
        }

        Task {
            let testProject = Project(
                name: "Test Project",
                path: "/tmp/test",
                lastCommitDate: Date().addingTimeInterval(-7 * 86400),
                isGitRepository: true
            )

            let message = settingsManager.settings.motivationStyle.generateMessage(for: testProject)
            print("📝 Test notification message: \(message)")

            await NotificationManager.shared.sendNotification(
                title: "Test Notification",
                body: message,
                project: testProject
            )
        }
    }
}

struct AISettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var isTestingConnection = false
    @State private var connectionStatus: String?
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable AI Insights", isOn: $settingsManager.settings.enableAIInsights)
                
                Text("Get personalized project insights and recommendations using local AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("AI Features")
                    .font(.headline)
            }
            
            if settingsManager.settings.enableAIInsights {
                Section {
                    TextField("Endpoint", text: $settingsManager.settings.ollamaEndpoint)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Model", text: $settingsManager.settings.ollamaModel)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button(isTestingConnection ? "Testing..." : "Test Connection") {
                            testConnection()
                        }
                        .disabled(isTestingConnection)
                        
                        if let status = connectionStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(status.contains("✅") ? .green : .red)
                        }
                    }
                } header: {
                    Text("Ollama Configuration")
                        .font(.headline)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Requires Ollama to be running locally")
                        Link("Download Ollama", destination: URL(string: "https://ollama.ai")!)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = nil
        
        Task {
            let testProject = Project(
                name: "Test",
                path: "/tmp/test",
                lastCommitDate: Date(),
                isGitRepository: true
            )
            
            if let _ = await AIService.shared.generateInsight(for: testProject) {
                await MainActor.run {
                    connectionStatus = "✅ Connected"
                }
            } else {
                await MainActor.run {
                    connectionStatus = "❌ Connection failed"
                }
            }
            
            await MainActor.run {
                isTestingConnection = false
            }
        }
    }
}

struct FoldersSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingFolderPicker = false
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Watch Folders")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingFolderPicker = true }) {
                    Label("Add Folder", systemImage: "plus")
                }
                .foregroundColor(Color(red: 0.22, green: 0.741, blue: 0.969))
            }
            .padding()
            
            List {
                ForEach(settingsManager.settings.watchFolders, id: \.self) { folder in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(Color(red: 0.22, green: 0.741, blue: 0.969))
                        
                        Text(folder)
                            .font(.system(size: 13, design: .monospaced))
                        
                        Spacer()
                        
                        Button(action: {
                            settingsManager.removeWatchFolder(folder)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            HStack {
                Button(isScanning ? "Scanning..." : "Rescan All Folders") {
                    rescanFolders()
                }
                .disabled(isScanning || settingsManager.settings.watchFolders.isEmpty)
                
                Spacer()
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                settingsManager.addWatchFolder(url.path)
            }
        }
    }
    
    private func rescanFolders() {
        isScanning = true
        Task {
            await projectStore.discoverProjects(in: settingsManager.settings.watchFolders)
            await MainActor.run {
                isScanning = false
            }
        }
    }
}

