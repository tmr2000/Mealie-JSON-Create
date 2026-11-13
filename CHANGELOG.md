# Changelog

Notable changes are recorded here, newest first, using [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) categories. Versioning follows the project policy in README.md, based on [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-11-13

### Fixed

- Preserve ingredients and numbered method steps from recognised structured source recipes instead of trusting model rewrites; retain cooking alternatives and use source portion counts.
- Discard descriptions not quoted from source; remove detected contradictory dietary descriptions and unsupported category/planning selections using configured evidence gates. Quick now checks final total time.
- Use the upper LOW cooking-range bound for recognised structured recipes and repair impossible total times with a disclosed prep-plus-cook estimate.
- Strengthened whole-recipe Vegetarian/Vegan rules and added configured checks to remove dietary tags contradicted by ingredient tags or recognised ingredient terms, with a review note. Conservative matching can also withhold tags for named plant alternatives.
- Constrain Ollama duration fields and explain single-value formatting; recover valid ISO duration ranges using the upper bound with a review note instead of failing conversion.

### Added

- Chicken curry regression fixture and adversarial QA checks, with an optional live run against installed Ollama models.
- Ollama category/tag selection from one editable configuration, shared by the prompt, structured schema and validation; selections appear in the preview and Mealie import JSON.
- Duplicate removal, canonical label casing and rejection of unknown classification labels; offline mode exports empty classification lists.
- Future developments document covering configuration editing, required tools, classification review and direct Mealie integration.

- Ollama extraction of prep, cook and total times and yield text, with missing values estimated and identified in a preview/export note.
- Offline parsing of labelled durations and clear notes for missing metadata.
- Prep, cook and total times in recipe previews and schema.org JSON exports.

### Changed

- The interface now always uses Ollama; removed the cookbook rewrite toggle and require an available model for every conversion. The offline parser remains available to scripts only.
- Replaced the split input/output workspace with full-workspace input and review stages, progress/error views and Back navigation preserving recipe text and settings.
- Enlarged recipe typography and moved yield, human-readable timings, boxed categories/tags, review notes and source attribution to a scrollable review sidebar.
- Project instructions now require README maintenance and documentation/version consistency checks, with version bumps reserved for requested releases.
- Categories and tags are implemented; required tools remain planned.

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
