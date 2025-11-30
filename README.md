# Flights

SwiftUI app for tracking flights and trips. Ships with mock data for quick previews and can pull live flight data when an API key is configured.

## Setup
- Requires Xcode 16 and iOS 17+ simulators.
- Add an AviationStack API key via `Config.local.xcconfig` (git-ignored). Example:  
  `AVIATIONSTACK_API_KEY = <your_key>`
- A sample `Config.example.xcconfig` is provided; the target already includes it and will pick up `Config.local.xcconfig` if present. The app falls back to mock data if no key is present.
- Optional: create a `.xcconfig` (git-ignored) to hold secrets and reference it from the target’s build settings instead of committing keys.

## Run & Test
- Open with `xed .` and run the `Flights` scheme on an iOS Simulator (e.g., iPhone 16).
- CLI build:  
  `xcodebuild -scheme Flights -destination "platform=iOS Simulator,name=iPhone 16" build`
- CLI tests:  
  `xcodebuild test -scheme Flights -destination "platform=iOS Simulator,name=iPhone 16"`

## Data & Services
- Live data: AviationStack (`AVIATIONSTACK_API_KEY`) is used for search and flight lookups when a key is present. Best results come from flight numbers (`AS338`, `DL220`). Airline names are supported with light inference (e.g., “Alaska” -> IATA `AS`).
- Offline/demo: Mock data remains available and is used automatically when no key or when API errors occur.
- User flights: persisted locally via `UserDefaults`; you can add flights manually in-app.

## Contributing
- See `AGENTS.md` for structure, commands, and coding guidelines.
- Please avoid committing secrets; keep API keys in local configs only.
