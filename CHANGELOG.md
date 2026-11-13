# Changelog

Notable changes are recorded here, newest first, using [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) categories. Versioning follows the project policy in README.md, based on [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.5] - 2026-11-13

### Changed

- The empty recipe-preview icon now uses a rounded-square background to match the app's other icons.

## [0.2.4] - 2026-11-13

### Added

- Changelog covering the initial local versions and a documented release/versioning policy.
- Repository instructions requiring changelog updates for future changes.
- Build checks requiring a valid version and matching dated changelog entry.

### Changed

- Build outputs always include the app version: MealieJsonCreate-0.2.4.exe and MealieJsonCreate-0.2.4.bundled.ps1.

## [0.2.3] - 2026-11-13

### Added

- Matching orange bowl icon for the application window and Windows executable.
- Reproducible icon generator with seven sizes, from 16 to 256 pixels.
- Embedded icon data so the built EXE requires no separate icon file.

## [0.2.2] - 2026-11-13

 - Test version, no changes

## [0.2.1] - 2026-11-13

### Changed

- Paste and Clear text controls now use visible button styling.

### Removed

- Example recipe placeholder text from the input editor.

## [0.2.0] - 2026-11-13

### Added

- Mealie-inspired WPF interface with dark surfaces, orange accents and scalable vector artwork.
- Readable recipe preview alongside the JSON output tab.
- Paste, clear, character count and Ctrl+Enter conversion controls.
- App version in the bottom-left corner.

### Changed

- Model refresh is an icon beside the Ollama model dropdown.
- Model discovery status is separate from recipe conversion status.
- Removed decorative headings and taglines from the workspace.

## [0.1.0] - 2026-11-13

### Added

- Initial PowerShell GUI for pasted recipe text and Mealie-compatible schema.org Recipe JSON.
- Deterministic offline parsing of labelled ingredients and methods.
- Optional Ollama extraction with cookbook-style instruction rewriting.
- Installed-model discovery from the configured Ollama server.
- Title override, source URL, JSON copy and UTF-8 file export.
- Background generation, validation checks and a PS2EXE build script.
