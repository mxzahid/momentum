import SwiftUI
import AppKit

@MainActor
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    override init() {
        super.init()
        Self.shared = self
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Momentum")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 700)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView()
            .environmentObject(ProjectStore.shared)
            .environmentObject(SettingsManager.shared))
        
        // Update menu bar icon based on projects
        updateStatusIcon()
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                updateStatusIcon()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func updateStatusIcon() {
        Task { @MainActor in
            if let button = statusItem?.button {
                button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Momentum")
            }
        }
    }

    static func updateIcon() {
        Task { @MainActor in
            if let button = Self.shared?.statusItem?.button {
                button.image = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis", accessibilityDescription: "Momentum")
            }
        }
    }

    private static var shared: MenuBarManager?
}

struct MenuBarPopoverView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                Text("Momentum")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: openMainWindow) {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Quick stats
            HStack(spacing: 20) {
                StatBadge(
                    value: projectStore.activeProjects.count,
                    label: "Active",
                    color: .green
                )
                
                StatBadge(
                    value: projectStore.inactiveProjects.count,
                    label: "Needs Attention",
                    color: .orange
                )
                
                StatBadge(
                    value: projectStore.projects.count,
                    label: "Total",
                    color: .blue
                )
            }
            .padding()
            
            Divider()
            
            // All projects
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(projectStore.projects) { project in
                        MenuBarProjectRow(project: project)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Refresh All") {
                    Task {
                        for project in projectStore.projects {
                            await projectStore.refreshProject(project)
                        }
                    }
                }
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 400, height: 700)
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MenuBarProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(timeAgoText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(project.momentumScore))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch project.activityStatus {
        case .active: return .green
        case .cooling: return .yellow
        case .inactive: return .orange
        case .dormant: return .red
        }
    }
    
    private var timeAgoText: String {
        let days = project.daysSinceLastActivity
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 30 { return "\(days / 7) weeks ago" }
        return "\(days / 30) months ago"
    }
}

