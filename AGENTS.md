# Repository Guidelines

## Project Structure & Module Organization
- App entry and environment setup: `Flights/FlightsApp.swift` with `FlightService` injected into `ContentView.swift`.
- UI composition: `Flights/Views/` for SwiftUI screens; shared SwiftUI previews live alongside views using `Preview Content/`.
- Domain models: `Flights/Models/` (`Flight`, `Trip`, `Airport`, `FlightStatus`) define app data.
- Services: `Flights/Services/FlightService.swift` owns state, mock generation, and `UserDefaults` persistence for user flights.
- Assets and configuration: `Flights/Assets.xcassets`, `Flights/Info.plist`, `Flights/Flights.entitlements`.
- Tests: unit tests in `FlightsTests/`, UI tests in `FlightsUITests/`.

## Build, Test, and Development Commands
- Open workspace in Xcode: `xed .` (or open `Flights.xcodeproj` directly).
- Build only: `xcodebuild -scheme Flights -destination "platform=iOS Simulator,name=iPhone 15" build`.
- Unit + UI tests: `xcodebuild test -scheme Flights -destination "platform=iOS Simulator,name=iPhone 15"`.
- Limit to UI tests while iterating: `xcodebuild test -scheme Flights -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:FlightsUITests`.
- SwiftUI previews: run from Xcode canvas; keep preview providers lightweight and deterministic.

## Coding Style & Naming Conventions
- Swift 5/SwiftUI, 4-space indentation, trim trailing whitespace; prefer `struct` for views/models, `class` only for `ObservableObject`.
- Naming: types and enums in UpperCamelCase; properties, functions, and cases in lowerCamelCase; match filenames to the primary type.
- Keep view state minimal; funnel business logic and data mutations through `FlightService`.
- Use explicit access control where meaningful; prefer `let` over `var` and early returns for clarity.
- Assets: name images and colors in lower-kebab or lowerCamelCase and reference via `Image("name")`/`Color("name")`.

## Testing Guidelines
- Framework: XCTest for unit tests (`FlightsTests.swift`) and UI flows (`FlightsUITests.swift`, `FlightsUITestsLaunchTests.swift`).
- Name tests `test<Behavior>` and keep data deterministic using the existing `MockData` helpers in services/models.
- Run the full `xcodebuild test` matrix before opening a PR; include at least one UI test for new interactive flows.
- Verify user flight persistence paths (UserDefaults) and trip filtering logic when touching `FlightService`.

## Commit & Pull Request Guidelines
- Commits: present-tense, imperative summaries (e.g., `Add past trip filtering`, `Fix UI test launch config`); keep related changes together.
- PRs: include a clear description, linked issue (if any), test results, and screenshots/recordings for visual changes.
- Avoid committing derived data; limit plist/entitlement changes to intentional edits and call them out in the PR description.
- Note any new simulator/device targets or dependencies added to commands or project settings.

## Security & Configuration Notes
- Current app uses mock/local data; avoid introducing secrets or real API keys. If a backend is added, gate credentials via Xcode configuration files that are git-ignored.
- Persistence is via `UserDefaults`; avoid storing sensitive information and document any new keys.
