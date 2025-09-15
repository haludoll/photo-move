# Repository Guidelines

## Project Structure & Module Organization
- `App/`: iOS app (SwiftUI), Xcode project and UI/unit tests (`photo-move.xcodeproj`, `photo-move.xcworkspace`, `photo-moveTests`, `photo-moveUITests`).
- `MediaLibrary/`: Swift Package with DDD layers: `Domain/`, `Application/`, `Infrastructure/`, `Presentation/`, `DependencyInjection/`, plus `Tests/` and `MediaLibrary.xctestplan`.
- `AppFoundation/`: Swift Package for app-wide scaffolding (`Sources/`, `Tests/`).
- `Scripts/`: helper scripts (`format.sh`, `build.sh`, `test.sh`, `xcode-swiftformat.sh`).
- `docs/`: architecture, specs, and issue docs.

## Build, Test, and Development Commands
- Format code: `./Scripts/format.sh` (uses `.swift-format`).
- Build packages: `./Scripts/build.sh` (runs formatter, then `swift build --package-path MediaLibrary`).
- Test packages: `./Scripts/test.sh` (runs formatter, then `swift test --package-path MediaLibrary`).
- Xcode: open `App/photo-move.xcworkspace` and use the `photo-move` scheme. Test plans: `App/photo-move.xctestplan`, `MediaLibrary/MediaLibrary.xctestplan`.

## Coding Style & Naming Conventions
- Swift 6; strict concurrency where applicable; prefer `struct` and protocols.
- Formatting: `.swift-format` (4 spaces, line length 120). Always run the formatter before committing.
- Naming: Types `UpperCamelCase`, methods/vars `lowerCamelCase`, protocols end with `Protocol` when clarifying intent; concrete implementations may use `Impl` (e.g., `MediaRepositoryImpl`).
- Files mirror type names; group by layer (e.g., `Domain/Entities/Media.swift`).

## Testing Guidelines
- Framework: `swift-testing` (`import Testing`, `@Test`, `#expect`).
- Structure tests by layer: `Tests/DomainTests/...`, `Tests/ApplicationTests/...`, etc. File names end with `Tests.swift`.
- Cover both happy-path and failure cases (e.g., permission denied, not found). Keep tests deterministic; use small helpers/mocks.

## Commit & Pull Request Guidelines
- Commits: short, imperative subject; scoped when helpful (e.g., "MediaLibrary: refactor thumbnail caching"). Japanese or English is OK. Reference issues (e.g., `#15`).
- PRs: clear description, linked issues, screenshots/screen recordings for UI changes, test plan, and impact notes. Require green CI and `./Scripts/format.sh` clean.

## Security & Configuration Tips
- Do not commit secrets or user-specific paths. Keep assets out of VCS unless required. Follow PhotoKit permissions best practices; local-only processing by design.

## Agent-Specific Notes
- Keep changes minimal and within scope; do not mass‑reformat. Obey this file’s guidance for any directories you touch.
- すべての思考および最終的な回答は日本語で記述すること。
