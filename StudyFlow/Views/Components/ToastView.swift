import SwiftUI

struct ToastView: View {
    @Binding var isPresented: Bool

    private let messages = [
        "Time to stretch your legs! 🚶",
        "Great session! Go take a short walk 🌿",
        "Stand up and move around! 💪",
        "Your body will thank you — take a walk! 🌤️",
        "Nice work! Now get some fresh air 🍃",
    ]

    @State private var message: String = ""
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isPresented {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.success)
                        .symbolEffect(.pulse, isActive: isPresented)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Session Complete!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)

                        Text(message)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                            .frame(width: 22, height: 22)
                            .background(Theme.surfaceLight.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.surface.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Theme.success.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Theme.success.opacity(0.15), radius: 20, y: 6)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                )
                .padding(.horizontal, Theme.paddingMd)
                .padding(.top, Theme.paddingSm)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                message = messages.randomElement() ?? messages[0]
                scheduleAutoDismiss()
            }
            .onDisappear {
                dismissTask?.cancel()
            }
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }

    private func scheduleAutoDismiss() {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                dismiss()
            }
        }
    }
}
