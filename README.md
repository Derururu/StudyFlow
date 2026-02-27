# StudyFlow ⏱

A native macOS Pomodoro timer and study tracking app built with SwiftUI & SwiftData.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Features

- **Pomodoro Timer** — Focus, short break, and long break phases with a gorgeous animated progress ring
- **Menu Bar Integration** — Live countdown in your macOS menu bar with tag & project dropdowns
- **Custom Tags** — Create and manage study tags with custom colors; toggle delete mode to remove tags (sessions reassigned to "General")
- **Project Mode** — Group study sessions by project; select a project from the timer or menu bar before starting a session
- **Adjustable Durations** — Tweak timer durations inline with ±5 min controls, or via Settings
- **Session Logging** — Every completed focus session is automatically saved with tag, project, duration, and timestamps
- **Statistics Dashboard** — Today's study time, weekly total, streak tracking, and a 7-day bar chart
- **Hover Tag Breakdown** — Hover over any bar in the weekly chart to see a floating pie chart of tag distribution for that day
- **Project Breakdown** — Select a project in the Stats dashboard to see a donut pie chart of time distribution by tag
- **Session History** — Browse past sessions grouped by date, filter by tag, swipe to delete
- **Notifications** — Native macOS notifications when phases complete, with optional sound
- **Keyboard Shortcut** — Press `Esc` to close the app window

## Screenshots

### Timer View
![Timer View](screenshots/timer.png)

### Menu Bar
![Menu Bar](screenshots/menubar.png)

### Statistics Dashboard
![Statistics Dashboard](screenshots/dashboard.png)

### Session History
![Session History](screenshots/history.png)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Data | SwiftData |
| Charts | Swift Charts |
| Timer | Combine (`Timer.publish`) |
| Notifications | UserNotifications |
| Platform | macOS 14+ (Sonoma) |

## Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

### Build & Run

```bash
# Clone the repo
git clone https://github.com/Derururu/StudyFlow.git
cd StudyFlow

# Generate the Xcode project
xcodegen generate

# Open in Xcode and run (⌘R)
open StudyFlow.xcodeproj
```

## Project Structure

```
StudyFlow/
├── StudyFlowApp.swift          # App entry point + MenuBarExtra
├── Models/
│   ├── StudySession.swift      # SwiftData model for logged sessions
│   ├── Subject.swift           # SwiftData model for custom tags
│   ├── Project.swift           # SwiftData model for projects
│   └── TimerState.swift        # Timer phases, status, config
├── ViewModels/
│   ├── TimerViewModel.swift    # Core timer logic (Observable)
│   └── StatsViewModel.swift    # Statistics calculations
├── Views/
│   ├── ContentView.swift       # Tab navigation + ESC handler
│   ├── TimerView.swift         # Main timer UI + tag/project pickers
│   ├── StatsView.swift         # Statistics dashboard + hover pie chart
│   ├── HistoryView.swift       # Session history
│   ├── SettingsView.swift      # App preferences
│   ├── MenuBarTimerView.swift  # Menu bar dropdown + project selector
│   └── Components/
│       ├── CircularProgressRing.swift
│       ├── StatCard.swift
│       ├── SessionRow.swift
│       └── ToastView.swift
├── Utils/
│   └── Theme.swift             # Design system (colors, gradients, spacing)
└── Assets.xcassets/            # App icon & accent color
```

## Design

- Dark theme with glassmorphism effects
- Indigo/violet gradients for focus, teal/blue for breaks
- Monospaced timer display with smooth animations
- Custom circular progress ring with glow effects
- Interactive hover tooltips with donut pie charts

## License

MIT

