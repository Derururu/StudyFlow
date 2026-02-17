import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \StudySession.startDate, order: .reverse) private var sessions: [StudySession]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSubjectFilter: String? = nil
    @Query(sort: \Subject.name) private var subjects: [Subject]

    var filteredSessions: [StudySession] {
        if let filter = selectedSubjectFilter {
            return sessions.filter { $0.subjectName == filter }
        }
        return sessions
    }

    var groupedSessions: [(key: String, sessions: [StudySession])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let grouped = Dictionary(grouping: filteredSessions) { session in
            formatter.string(from: session.startDate)
        }

        return grouped.map { (key: $0.key, sessions: $0.value) }
            .sorted { first, second in
                guard let d1 = first.sessions.first?.startDate,
                      let d2 = second.sessions.first?.startDate else { return false }
                return d1 > d2
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text("\(filteredSessions.count) sessions")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, Theme.paddingLg)
            .padding(.top, Theme.paddingLg)
            .padding(.bottom, Theme.paddingSm)

            // Subject filter
            subjectFilter
                .padding(.horizontal, Theme.paddingLg)
                .padding(.bottom, Theme.paddingMd)

            // Sessions list
            if filteredSessions.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.textMuted)

                    Text("No sessions yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textMuted)

                    Text("Complete a pomodoro to see it here")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted.opacity(0.7))
                }
                Spacer()
            } else {
                List {
                    ForEach(groupedSessions, id: \.key) { group in
                        Section {
                            ForEach(group.sessions) { session in
                                SessionRow(session: session)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets())
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteSession(session)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text(group.key)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textMuted)
                                    .tracking(1)

                                Spacer()

                                let dayTotal = group.sessions.reduce(0) { $0 + $1.duration }
                                Text(formatDuration(dayTotal))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background)
    }

    // MARK: - Subject Filter

    private var subjectFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "All",
                    isSelected: selectedSubjectFilter == nil
                ) {
                    selectedSubjectFilter = nil
                }

                ForEach(subjects) { subject in
                    FilterChip(
                        label: subject.name,
                        isSelected: selectedSubjectFilter == subject.name,
                        color: Color(hex: subject.colorHex)
                    ) {
                        selectedSubjectFilter = subject.name
                    }
                }
            }
        }
    }

    private func deleteSession(_ session: StudySession) {
        modelContext.delete(session)
        try? modelContext.save()
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? color.opacity(0.2)
                        : Theme.surfaceLight.opacity(0.3)
                )
                .clipShape(Capsule())
                .overlay(
                    isSelected
                        ? Capsule().stroke(color.opacity(0.4), lineWidth: 1)
                        : nil
                )
        }
        .buttonStyle(.plain)
    }
}
