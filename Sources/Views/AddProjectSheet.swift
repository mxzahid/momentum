import SwiftUI

struct AddProjectSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingFolderPicker = false
    @State private var selectedPath: String = ""
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Add Project")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a project folder to track")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Project Location", systemImage: "folder")
                    .font(.headline)
                
                HStack {
                    if selectedPath.isEmpty {
                        Text("No folder selected")
                            .foregroundColor(.secondary)
                    } else {
                        Text(selectedPath)
                            .font(.system(size: 13, design: .monospaced))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button("Choose...") {
                        showingFolderPicker = true
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(isScanning ? "Adding..." : "Add Project") {
                    addProject()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedPath.isEmpty || isScanning)
            }
        }
        .padding()
        .frame(width: 500, height: 250)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedPath = url.path
            }
        }
    }
    
    private func addProject() {
        guard !selectedPath.isEmpty else { return }
        
        // Check if already tracked
        if projectStore.projects.contains(where: { $0.path == selectedPath }) {
            dismiss()
            return
        }
        
        isScanning = true
        
        Task {
            if let project = await ProjectDiscoveryService.shared.scanSingleProject(at: selectedPath) {
                await MainActor.run {
                    projectStore.addProject(project)
                    isScanning = false
                    dismiss()
                }
            } else {
                await MainActor.run {
                    isScanning = false
                }
            }
        }
    }
}

