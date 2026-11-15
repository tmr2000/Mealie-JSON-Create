# Changelog

Notable changes are recorded here, newest first, using [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) categories. Versioning follows the project policy in README.md, based on [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0-rc.1] - 2026-11-15

- Move Local AI controls into Settings and persist the local/network Ollama server and default model between launches (minor capability impact). Local Ollama installation is not required.


- Add a focused Ollama tag-contradiction review with evidence-backed removals, compatible-tag controls, per-tag reasons and fallback notes (minor capability).
- Preserve manual choices on local recheck and clear stale model resolutions after recipe/timing edits.


- Fix automatic Vegetarian/Vegan recommendations surviving explicit ingredient contradictions, including chicken curry and customised dietary prompts; preserve deliberate manual overrides (patch impact).


- Fix repeated tag instructions in classification settings by defining individual defaults for every approved tag and sending those same definitions to Ollama.
- Upgrade unchanged legacy group instructions while preserving customised rules, names and removals (patch impact).


### Regression corpus

- Added three attributed website recipe-card adaptations, four deliberately untidy generated recipes and an incomplete-input rejection case, with independent expected source facts.
- Added deterministic and optional live Ollama corpus checks, per-case reports and export snapshots; integrated offline coverage into local and hosted release checks.
- Fixed numbered-list cleanup stripping the integer part from decimal quantities such as 1.75 cups (patch impact).


- Organise unfamiliar recipe layouts using source-line IDs, combining split ingredient quantities and method paragraphs without model-written recipe text. Reject missing, duplicate or invented IDs. Minor capability change.

- Fixed loading saved category and tag lists in Windows PowerShell 5.1.

- Highlight Add tag and Add category with orange plus buttons in classification settings (visual polish).

- Simplified classification settings to show compact names and a single editor for the selected entry.

- Added a top-bar classification settings editor for per-user tag and category names and Ollama selection rules (minor feature).

- Preselect approved tag recommendations, including uncertain or conflicting suggestions, for manual correction before import.

- Split Ollama conversion into conditional extraction, missing-field estimation and classification requests. Preserve source wording and resolve evidence IDs locally.

### Added

- Evidence-based classification decisions with scoped reasons, source excerpts and suggestions for manual review, displayed in the category/tag editors.
- Local classification rechecks after recipe/timing edits, stale-evidence indicators and retention of manual checkbox choices.
- Dedicated classification regressions in local and hosted release checks.

### Changed

- Evaluate every approved label to recover missed tags; distinguish central ingredients from stock/sauce/garnish evidence and restrict dish identity to source titles.
- Require explicit cuisine evidence, affirmative planning guidance and actual appliance use; keep estimated Quick and optional appliance methods for review.
- Recognise configured plant alternatives while withholding dietary tags for conflicting or ambiguous ingredients.

## [0.5.0] - 2026-11-15

### Added

- Edit ingredients and numbered recipe steps as individual themed fields in the main window, with add/remove and apply/cancel controls; flag source QA counts as historical after content edits.

### Changed

- Split Recipe preview into Ingredients and Recipe tabs, retaining JSON.
- Use accessible pencil buttons for metadata and content editing; replace the Edit details tab and separate editor windows with inline editors and themed category/tag checkboxes.
- Disable export and other review actions while editing; keep drafts out of JSON until successfully applied.

## [0.4.0] - 2026-11-14

### Changed

- The green header button stays hidden during the background launch check, when up to date or when checking fails. It appears as "Update available" only after finding a newer stable installer, with the version in its tooltip; download/install actions remain available. Version impact: patch-level UI change.

### Fixed

- Allow manually starting the Release workflow for an existing version tag if its original push did not trigger a run; build the tagged source and retain the existing-release overwrite protection.

### Changes from 0.4.0-rc.1

#### Added

- Interactive reusable release wizard: prepare version/dated changelog/README, run local checks, review notes and changed files, then explicitly confirm staging, committing and pushing the release. Includes prepare-only mode, resuming a prepared version and carrying candidate notes into the stable final.
- Tag-triggered GitHub Actions release pipeline, changelog-derived release notes and an explicit release push helper; builds and publishes portable/installer EXEs, marking release candidates as prereleases without overwriting existing releases.
- Program Files installer build with Start menu/optional desktop shortcuts and uninstall support; background stable-release checks and verified, user-initiated installer updates from GitHub.
- Review-screen detail editor for yield, timings and approved category/tag selections; applying edits updates preview and export JSON.

#### Changed

- Missing yield, timings, categories and tags no longer block conversion; unknown yield remains blank. Pending edits must be applied before export.

## [0.4.0-rc.1] - 2026-11-14

### Added

- Interactive reusable release wizard: prepare version/dated changelog/README, run local checks, review notes and changed files, then explicitly confirm staging, committing and pushing the release. Includes prepare-only mode, resuming a prepared version and carrying candidate notes into the stable final.
- Tag-triggered GitHub Actions release pipeline, changelog-derived release notes and an explicit release push helper; builds and publishes portable/installer EXEs, marking release candidates as prereleases without overwriting existing releases.
- Program Files installer build with Start menu/optional desktop shortcuts and uninstall support; background stable-release checks and verified, user-initiated installer updates from GitHub.
- Review-screen detail editor for yield, timings and approved category/tag selections; applying edits updates preview and export JSON.

### Changed

- Missing yield, timings, categories and tags no longer block conversion; unknown yield remains blank. Pending edits must be applied before export.

## [0.3.1-rc.2] - 2026-11-14

### Fixed

- Accept plain ingredient lines and blank-line-separated method paragraphs without requiring bullets; preserve copied indentation boundaries, wrapped paragraphs and uncolonised Serves values. Added steak pie regression coverage.
- Preserve grouped ingredients, bulleted methods and indented continuation lines; stop at recognised notes/equipment/nutrition boundaries and retain source notes.
- Prefer labelled source times and yield, discard model-written metadata explanations, and block ambiguous explicit recipe sections or inconsistent supplied total times.
- Gate dish-type tags against source vocabulary and appliance tags against positive parsed-method evidence, excluding equipment-only and known negated mentions.

### Added

- Separate QA summary in the preview and shepherd’s pie regression checks covering ingredient/step loss, source metadata, notes and false appliance claims.


## [0.3.1-rc.1] - 2026-11-13

### Added

- Animated activity bar beneath the existing conversion message while Ollama runs; stops and hides on success or failure without implying percentage completion.
- Release-candidate build versions using -rc.N in the app footer, changelog and output filenames, with numeric Windows file metadata derived from the base version.

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
