import SwiftUI

struct SessionRow: View {
    let session: StudySession

    var body: some View {
        HStack(spacing: 12) {
            // Subject color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: session.subjectColorHex))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.subjectName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text(session.timeRange)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(session.formattedDuration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)

                HStack(spacing: 2) {
                    ForEach(0..<session.pomodoroCount, id: \.self) { _ in
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Theme.accent.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, Theme.paddingMd)
        .padding(.vertical, Theme.paddingSm)
    }
}
