import SwiftUI

struct SettingsView: View {
    @State private var config = TimerConfig.load()

    var body: some View {
        Form {
            Section("Timer Durations") {
                durationSlider(
                    label: "Focus",
                    value: Binding(
                        get: { config.focusDuration / 60 },
                        set: { config.focusDuration = $0 * 60 }
                    ),
                    range: 5...60,
                    unit: "min"
                )

                durationSlider(
                    label: "Short Break",
                    value: Binding(
                        get: { config.shortBreakDuration / 60 },
                        set: { config.shortBreakDuration = $0 * 60 }
                    ),
                    range: 1...15,
                    unit: "min"
                )

                durationSlider(
                    label: "Long Break",
                    value: Binding(
                        get: { config.longBreakDuration / 60 },
                        set: { config.longBreakDuration = $0 * 60 }
                    ),
                    range: 5...30,
                    unit: "min"
                )

                Stepper(
                    "Long break every \(config.longBreakInterval) pomodoros",
                    value: $config.longBreakInterval,
                    in: 2...8
                )
            }

            Section("Notifications") {
                Toggle("Sound on completion", isOn: $config.soundEnabled)
                Toggle("System notifications", isOn: $config.notificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 360)
        .onChange(of: config.focusDuration) { _, _ in config.save() }
        .onChange(of: config.shortBreakDuration) { _, _ in config.save() }
        .onChange(of: config.longBreakDuration) { _, _ in config.save() }
        .onChange(of: config.longBreakInterval) { _, _ in config.save() }
        .onChange(of: config.soundEnabled) { _, _ in config.save() }
        .onChange(of: config.notificationsEnabled) { _, _ in config.save() }
    }

    private func durationSlider(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unit: String
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 90, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )

            Text("\(value.wrappedValue) \(unit)")
                .frame(width: 55, alignment: .trailing)
                .monospacedDigit()
        }
    }
}
