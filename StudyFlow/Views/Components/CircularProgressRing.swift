import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    let phase: TimerPhase
    let timeString: String
    let phaseLabel: String

    @State private var animatedProgress: Double = 0

    var ringGradient: AngularGradient {
        let colors: [Color] = phase == .focus
            ? [Color(hex: "#7C5CFC"), Color(hex: "#A855F7"), Color(hex: "#7C5CFC")]
            : [Color(hex: "#00C9A7"), Color(hex: "#00B4D8"), Color(hex: "#00C9A7")]

        return AngularGradient(
            gradient: Gradient(colors: colors),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var glowColor: Color {
        phase == .focus ? Theme.accent : Theme.success
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.surfaceLight.opacity(0.3), lineWidth: Theme.ringLineWidth)
                .frame(width: Theme.ringSize, height: Theme.ringSize)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: Theme.ringLineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: Theme.ringSize, height: Theme.ringSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor.opacity(0.4), radius: 8)

            // Center content
            VStack(spacing: 6) {
                Text(phaseLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                Text(timeString)
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.linear(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            animatedProgress = progress
        }
    }
}
