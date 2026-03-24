import SwiftUI
import SwiftData

struct SubjectPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.createdAt) private var subjects: [Subject]
    @Query private var sessions: [StudySession]
    
    @Binding var selectedSubjectName: String
    @Binding var selectedSubjectColorHex: String
    
    @State private var showingSubjectEditor = false
    @State private var newSubjectName = ""
    @State private var selectedTagColor = "#7C5CFC"
    @State private var isDeletingTags = false

    var body: some View {
        VStack(spacing: 8) {
            Text("TAGS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.5)

            if subjects.isEmpty {
                Button {
                    showingSubjectEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Create your first tag")
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
                            ForEach(subjects) { subject in
                                Button {
                                    if isDeletingTags {
                                        deleteTag(subject)
                                    } else {
                                        selectedSubjectName = subject.name
                                        selectedSubjectColorHex = subject.colorHex
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isDeletingTags {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(.red)
                                        } else {
                                            Circle()
                                                .fill(Color(hex: subject.colorHex))
                                                .frame(width: 8, height: 8)
                                        }

                                        Text(subject.name)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(
                                        isDeletingTags
                                            ? .red
                                            : selectedSubjectName == subject.name
                                                ? Theme.textPrimary
                                                : Theme.textSecondary
                                    )
                                    .background(
                                        isDeletingTags
                                            ? Color.red.opacity(0.1)
                                            : selectedSubjectName == subject.name
                                                ? Color(hex: subject.colorHex).opacity(0.2)
                                                : Theme.surfaceLight.opacity(0.3)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        isDeletingTags
                                            ? Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1)
                                            : selectedSubjectName == subject.name
                                                ? Capsule().stroke(Color(hex: subject.colorHex).opacity(0.5), lineWidth: 1)
                                                : nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteTag(subject)
                                    } label: {
                                        Label("Delete Tag", systemImage: "trash")
                                    }
                                }
                            }

                            Button {
                                isDeletingTags = false
                                showingSubjectEditor = true
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
                                    isDeletingTags.toggle()
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(isDeletingTags ? .white : Theme.textMuted)
                                    .frame(width: 28, height: 28)
                                    .background(isDeletingTags ? Color.red.opacity(0.8) : Theme.surfaceLight.opacity(0.3))
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
        .sheet(isPresented: $showingSubjectEditor) {
            VStack(spacing: 16) {
                Text("New Tag")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                TextField("Tag name (e.g. DSA, Physics, Reading)", text: $newSubjectName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)

                VStack(spacing: 6) {
                    Text("COLOR")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textMuted)
                        .tracking(1)

                    HStack(spacing: 8) {
                        ForEach(Subject.tagColors, id: \.self) { colorHex in
                            Button {
                                selectedTagColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        selectedTagColor == colorHex
                                            ? Circle().stroke(.white, lineWidth: 2)
                                            : nil
                                    )
                                    .shadow(color: selectedTagColor == colorHex
                                        ? Color(hex: colorHex).opacity(0.6) : .clear,
                                        radius: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") {
                        newSubjectName = ""
                        showingSubjectEditor = false
                    }

                    Button("Add Tag") {
                        guard !newSubjectName.isEmpty else { return }
                        let subject = Subject(name: newSubjectName, colorHex: selectedTagColor)
                        modelContext.insert(subject)
                        try? modelContext.save()
                        
                        selectedSubjectName = newSubjectName
                        selectedSubjectColorHex = selectedTagColor
                        newSubjectName = ""
                        showingSubjectEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newSubjectName.isEmpty)
                }
            }
            .padding(Theme.paddingLg)
            .frame(width: 340, height: 200)
            .background(Theme.background)
        }
    }

    private func deleteTag(_ subject: Subject) {
        let matchingSessions = sessions.filter { $0.subjectName == subject.name }
        for session in matchingSessions {
            session.subjectName = "General"
            session.subjectColorHex = "#868E96"
        }

        if selectedSubjectName == subject.name {
            selectedSubjectName = subjects.first(where: { $0.id != subject.id })?.name ?? ""
            selectedSubjectColorHex = subjects.first(where: { $0.id != subject.id })?.colorHex ?? "#868E96"
        }
        modelContext.delete(subject)
        try? modelContext.save()

        if subjects.count <= 2 {
            isDeletingTags = false
        }
    }
}
