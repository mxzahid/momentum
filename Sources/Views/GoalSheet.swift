import SwiftUI

struct GoalSheet: View {
    let project: Project
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var projectStore: ProjectStore

    @State private var goals: [ProjectGoal]
    @State private var newGoalText = ""
    @State private var newGoalHasDeadline = false
    @State private var newGoalDeadline = Date().addingTimeInterval(30 * 86400)
    @State private var editingGoal: ProjectGoal?
    @FocusState private var isNewGoalEditorFocused: Bool

    init(project: Project) {
        self.project = project
        _goals = State(initialValue: project.goals)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Project Goals")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Track multiple goals for \(project.name)")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Goals List
            ScrollView {
                VStack(spacing: 12) {
                    if goals.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "target")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No goals yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Add your first goal below")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        )
                    } else {
                        ForEach(goals) { goal in
                            GoalRow(
                                goal: goal,
                                onToggleComplete: { toggleGoalCompletion(goal) },
                                onEdit: { editingGoal = goal },
                                onDelete: { deleteGoal(goal) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 300)

            Divider()

            // Add New Goal Section
            VStack(alignment: .leading, spacing: 12) {
                Label("Add New Goal", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.22, green: 0.741, blue: 0.969))

                TextEditor(text: $newGoalText)
                    .font(.body)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3), lineWidth: 1)
                    )
                    .focused($isNewGoalEditorFocused)

                HStack {
                    Toggle("Set Deadline", isOn: $newGoalHasDeadline)
                        .font(.subheadline)

                    if newGoalHasDeadline {
                        DatePicker(
                            "",
                            selection: $newGoalDeadline,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }

                Button(action: addNewGoal) {
                    Label("Add Goal", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            .cornerRadius(10)

            // Bottom Actions
            HStack {
                Button("Close") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.escape)
            }
        }
        .padding()
        .frame(width: 600, height: 700)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isNewGoalEditorFocused = true
            }
        }
        .sheet(item: $editingGoal) { goal in
            EditGoalSheet(goal: goal) { updatedGoal in
                if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                    goals[index] = updatedGoal
                }
            }
        }
    }

    private func addNewGoal() {
        let trimmedText = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let newGoal = ProjectGoal(
            text: trimmedText,
            deadline: newGoalHasDeadline ? newGoalDeadline : nil
        )
        goals.append(newGoal)

        // Reset form
        newGoalText = ""
        newGoalHasDeadline = false
        newGoalDeadline = Date().addingTimeInterval(30 * 86400)
        isNewGoalEditorFocused = true
    }

    private func toggleGoalCompletion(_ goal: ProjectGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].isCompleted.toggle()
            goals[index].completedDate = goals[index].isCompleted ? Date() : nil
        }
    }

    private func deleteGoal(_ goal: ProjectGoal) {
        goals.removeAll { $0.id == goal.id }
    }

    private func saveAndDismiss() {
        var updated = project
        updated.goals = goals
        projectStore.updateProject(updated)
        dismiss()
    }
}

struct GoalRow: View {
    let goal: ProjectGoal
    let onToggleComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onToggleComplete) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(goal.isCompleted ? .green : Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.6))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.text)
                    .font(.system(size: 14))
                    .strikethrough(goal.isCompleted)
                    .foregroundColor(goal.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let deadline = goal.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(deadline, style: .date)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(isOverdue(deadline) && !goal.isCompleted ? .red : .secondary)
                    }

                    if goal.isCompleted, let completedDate = goal.completedDate {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 10))
                            Text("Completed \(completedDate, style: .date)")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            if isHovered && !goal.isCompleted {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.22, green: 0.741, blue: 0.969))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(goal.isCompleted ? Color.green.opacity(0.05) : Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(goal.isCompleted ? Color.green.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func isOverdue(_ deadline: Date) -> Bool {
        deadline < Date()
    }
}

struct EditGoalSheet: View {
    let goal: ProjectGoal
    let onSave: (ProjectGoal) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var text: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @FocusState private var isEditorFocused: Bool

    init(goal: ProjectGoal, onSave: @escaping (ProjectGoal) -> Void) {
        self.goal = goal
        self.onSave = onSave
        _text = State(initialValue: goal.text)
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Date().addingTimeInterval(30 * 86400))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Goal")
                .font(.title2)
                .fontWeight(.bold)

            TextEditor(text: $text)
                .font(.body)
                .frame(height: 120)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.22, green: 0.741, blue: 0.969).opacity(0.3), lineWidth: 1)
                )
                .focused($isEditorFocused)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Set Deadline", isOn: $hasDeadline)
                    .font(.headline)

                if hasDeadline {
                    DatePicker(
                        "Target Date",
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    var updated = goal
                    updated.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.deadline = hasDeadline ? deadline : nil
                    onSave(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: hasDeadline ? 500 : 320)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isEditorFocused = true
            }
        }
    }
}
