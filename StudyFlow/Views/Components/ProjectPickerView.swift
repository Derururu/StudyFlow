import SwiftUI
import SwiftData

struct ProjectPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query private var sessions: [StudySession]
    
    @Binding var selectedProjectName: String
    @Binding var selectedProjectColorHex: String
    
    @State private var showingProjectEditor = false
    @State private var newProjectName = ""
    @State private var selectedProjectColor = "#FF6B6B"
    @State private var isDeletingProjects = false

    var body: some View {
        VStack(spacing: 8) {
            Text("PROJECTS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.5)

            if projects.isEmpty {
                Button {
                    showingProjectEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Create your first project")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "None" option to deselect project
                            Button {
                                if !isDeletingProjects {
                                    selectedProjectName = ""
                                    selectedProjectColorHex = ""
                                }
                            } label: {
                                Text("None")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(
                                        selectedProjectName.isEmpty
                                            ? Theme.textPrimary
                                            : Theme.textSecondary
                                    )
                                    .background(
                                        selectedProjectName.isEmpty
                                            ? Theme.surfaceLight.opacity(0.6)
                                            : Theme.surfaceLight.opacity(0.3)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        selectedProjectName.isEmpty
                                            ? Capsule().stroke(Theme.textMuted.opacity(0.5), lineWidth: 1)
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)

                            ForEach(projects) { project in
                                Button {
                                    if isDeletingProjects {
                                        deleteProject(project)
                                    } else {
                                        selectedProjectName = project.name
                                        selectedProjectColorHex = project.colorHex
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isDeletingProjects {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.red)
                                        } else {
                                            Circle()
                                                .fill(Color(hex: project.colorHex))
                                                .frame(width: 8, height: 8)
                                        }

                                        Text(project.name)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(
                                        isDeletingProjects
                                            ? .red
                                            : selectedProjectName == project.name
                                                ? Theme.textPrimary
                                                : Theme.textSecondary
                                    )
                                    .background(
                                        isDeletingProjects
                                            ? Color.red.opacity(0.1)
                                            : selectedProjectName == project.name
                                                ? Color(hex: project.colorHex).opacity(0.2)
                                                : Theme.surfaceLight.opacity(0.3)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        isDeletingProjects
                                            ? Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)
                                            : selectedProjectName == project.name
                                                ? Capsule().stroke(Color(hex: project.colorHex).opacity(0.5), lineWidth: 1)
                                                : nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteProject(project)
                                    } label: {
                                        Label("Delete Project", systemImage: "trash")
                                    }
                                }
                            }

                            Button {
                                isDeletingProjects = false
                                showingProjectEditor = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.textMuted)
                                    .frame(width: 28, height: 28)
                                    .background(Theme.surfaceLight.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDeletingProjects.toggle()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isDeletingProjects ? .white : Theme.textMuted)
                                    .frame(width: 28, height: 28)
                                    .background(isDeletingProjects ? Color.red.opacity(0.8) : Theme.surfaceLight.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(minWidth: geo.size.width)
                    }
                }
                .frame(height: 34)
            }
        }
        .sheet(isPresented: $showingProjectEditor) {
            VStack(spacing: 16) {
                Text("New Project")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                TextField("Project name (e.g. Thesis, App Dev, Research)", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                VStack(spacing: 6) {
                    Text("COLOR")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textMuted)
                        .tracking(1)

                    HStack(spacing: 8) {
                        ForEach(Project.projectColors, id: \.self) { colorHex in
                            Button {
                                selectedProjectColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        selectedProjectColor == colorHex
                                            ? Circle().stroke(.white, lineWidth: 2)
                                            : nil
                                    )
                                    .shadow(color: selectedProjectColor == colorHex
                                        ? Color(hex: colorHex).opacity(0.6) : .clear,
                                        radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") {
                        newProjectName = ""
                        showingProjectEditor = false
                    }

                    Button("Add Project") {
                        guard !newProjectName.isEmpty else { return }
                        let project = Project(name: newProjectName, colorHex: selectedProjectColor)
                        modelContext.insert(project)
                        try? modelContext.save()
                        
                        selectedProjectName = newProjectName
                        selectedProjectColorHex = selectedProjectColor
                        newProjectName = ""
                        showingProjectEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProjectName.isEmpty)
                }
            }
            .padding(Theme.paddingLg)
            .frame(width: 340, height: 200)
            .background(Theme.background)
        }
    }

    private func deleteProject(_ project: Project) {
        let matchingSessions = sessions.filter { $0.projectName == project.name }
        for session in matchingSessions {
            session.projectName = ""
            session.projectColorHex = ""
        }

        if selectedProjectName == project.name {
            selectedProjectName = ""
            selectedProjectColorHex = ""
        }
        modelContext.delete(project)
        try? modelContext.save()

        if projects.count <= 2 {
            isDeletingProjects = false
        }
    }
}
