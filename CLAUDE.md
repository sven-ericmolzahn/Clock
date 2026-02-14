# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a macOS SwiftUI menubar app using Xcode. Build and run via:

```bash
xcodebuild -project Clock.xcodeproj -scheme Clock build
xcodebuild -project Clock.xcodeproj -scheme Clock -destination 'platform=macOS' test
```

Or open `Clock.xcodeproj` in Xcode and use Cmd+R to run, Cmd+U to test.

## Architecture

- **Menubar-only SwiftUI app** (`LSUIElement = YES`) — no dock icon, no main window
- **`@Observable` AppState** manages all settings and a 1-second timer for live clock updates
- **UserDefaults** persistence for settings (format strings, booleans) and world clocks (Codable JSON)

### Files

- **ClockApp.swift** — `@main` entry point; `MenuBarExtra` with `.window` style + `Settings` scene
- **AppState.swift** — `@Observable` singleton: timer, formats, world clocks, menubar text computation
- **WorldClock.swift** — `Identifiable`/`Codable` model with label and time zone identifier
- **MenuBarPanel.swift** — Popover content: local clock, world clock list, Settings/Quit buttons
- **LocalClockView.swift** — Large formatted local time + full date
- **WorldClockRow.swift** — Single world clock: label, UTC offset, formatted time
- **SettingsView.swift** — `TabView` with General and World Clocks tabs
- **GeneralSettingsTab.swift** — Format pattern fields with live previews, menubar toggle
- **WorldClocksSettingsTab.swift** — Add/remove/reorder world clocks with time zone picker

## Key Conventions

- Swift 5.0, macOS 26.1 deployment target
- `@MainActor` isolation with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- Unit tests use Swift Testing framework (`@Test`, `#expect()`)
- App sandboxing and hardened runtime are enabled
- `DateFormatter.dateFormat` uses raw Unicode/ICU patterns — user controls exact output
- Project uses `PBXFileSystemSynchronizedRootGroup` — new files in `Clock/` are auto-included
