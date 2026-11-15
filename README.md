# Mealie JSON Create

A Windows PowerShell WPF app for turning pasted recipe text into schema.org Recipe JSON for Mealie's HTML/JSON import. The Mealie-inspired dark theme has warm orange accents, rounded panels and scalable vector artwork. UI resources are embedded; no browser, downloaded fonts or image files are needed.

Current release: **0.5.0** (`MealieJsonCreate-0.5.0.exe`, `MealieJsonCreate-0.5.0-Setup.exe`). See CHANGELOG.md for changes. Downloads become available after the release pipeline succeeds.

Previous local release: **0.3.0** (`MealieJsonCreate-0.3.0.exe`). This minor release adds time/yield metadata, controlled classification, a two-stage interface and recipe QA safeguards. **Ollama is now required by the interface**; the offline parser is available only to scripts. AI estimates still require review.

## Run

Requires Windows and Windows PowerShell 5.1 (included with Windows). From this folder:

```powershell
powershell.exe -NoProfile -STA -File .\MealieJsonCreate.ps1
```

The app uses two stages, each filling the window workspace:

1. **Recipe text:** paste one recipe, optionally supply a title override and source URL in the settings sidebar, select an installed Ollama model, then choose Convert recipe (or Ctrl+Enter). The input panel includes Paste, Clear text and a character count. Ollama is always used; there is no offline toggle.
2. **Review your recipe:** opens immediately with conversion progress, then displays separate Ingredients and Recipe tabs, with numbered method steps in Recipe. A scrollable left sidebar contains boxed yield, readable timings, category/tag chips, review notes and the source URL when supplied. Use pencil buttons beside yield, timing, categories, tags, ingredients and method to edit in the main window. Switch between Ingredients, Recipe and JSON and copy into Mealie's HTML/JSON recipe import or save as UTF-8 JSON. Export buttons stay disabled until conversion succeeds.

Use **Back to recipe** to return to stage 1 with your text, title, source URL and model settings preserved. Back also works during conversion; the background request continues, and another conversion cannot start until it finishes. Errors appear in the footer (hover for full details); the review stage directs you back to correct the input or settings. Ctrl+Enter only starts conversion from stage 1.

Release candidate 0.3.1-rc.1 adds an animated activity bar beneath the existing generation text while conversion is running. It indicates an active request, not a percentage or proof that the server is advancing, and stops on success or failure. This change is included in the release candidate and is not included in the existing 0.3.0 EXE. The GUI checks cover its running, success and error states.

The window resizes down to 1080 x 700 device-independent pixels, with scrolling for settings, metadata and recipe content. Stages fill the workspace without forcing Windows fullscreen/maximised mode. Windows PowerShell 5.1 supports the WPF interface; PowerShell 7 is not required.

Review quantities and instructions before import. This is an import document, not a Mealie backup or native database export. No Mealie credentials are needed. Source URL records attribution; the app does not fetch websites.

## Core offline parser (not available in the interface)

The deterministic offline parser remains available for scripts and core checks through `ConvertTo-RecipeJson` without `-UseOllama`; the application interface requires Ollama. For this parser, use a title on the first line, Ingredients and Method (or Instructions/Directions) headings, and one ingredient or step per line. Optional description lines go between the title and Ingredients. Serves, Servings or Yield metadata may appear on its own line. Yield text is preserved (for example `12 muffins`). Label durations as `Prep time: 10 minutes`, `Cook time: 1 hour` and `Total time: 1 hour 20 minutes`; ISO 8601 values such as `PT20M` also work. Missing offline durations remain empty and missing yield remains blank, with a preview note. Offline mode cannot estimate missing metadata. Example:

```text
Tomato pasta
Serves: 2
Ingredients
200 g pasta
1 tin tomatoes
Method
Boil the pasta.
Add the tomatoes and stir.
```

Offline mode preserves wording, normalises whitespace, removes list prefixes and applies initial capitals and terminal punctuation to steps. Identical input produces identical JSON. It does not perform grammar correction or reliably distinguish arbitrary mixed text.

## Ollama setup (required)

The model dropdown lists every installed model reported by the selected server's `/api/tags` endpoint, rather than models available for download or a fixed list. Compare it with `ollama list` against the same server. If both show only one model, check whether the other models belong to a different Ollama instance or model directory. The refresh icon immediately to the right of the dropdown reloads this list.

Install and start Ollama separately, download a suitable text model (for example `ollama pull llama3.2`), select an installed model from the dropdown. The default server is http://localhost:11434. The app queries `/api/tags` on opening and after URL edits; Refresh models reloads the list and retains your selection when available. Discovery runs in the background with a ten-second timeout. Empty or unreachable servers show a status message beside the model controls, independently of recipe conversion status. Ollama conversion requires an available model. Mixed website copy or LLM text is sent to the configured endpoint. Localhost keeps generation on your machine; changing the endpoint sends text to that server.

For unstructured input, Ollama rewrites terse methods into moderately detailed cookbook-style paragraphs in British English, explaining actions and their purpose when supported by the source. Related actions stay grouped into logical steps. The prompt preserves quantities, preparation notes, timings and cooking alternatives, and forbids invented recipe facts or a method where none was supplied. Simple steps can remain short. Review the result: these are model instructions, not a guarantee of factual preservation.

Generation runs in a background runspace so the GUI remains responsive. Requests time out after 180 seconds. Structured output, temperature zero, seed 42 and a fixed British English prompt improve consistency. Exact model wording is not guaranteed across model/server versions or hardware; review extracted facts. Missing ingredients or instructions cause a validation error rather than an invented recipe. The model preserves timings, temperatures and quantities in the instruction text and supplies `prepTime`, `cookTime`, `totalTime` (ISO 8601 durations) and `recipeYield` (yield text). It uses source values where supplied and estimates missing metadata from the recipe. Total time includes waits and overlapping tasks. A note in the preview and JSON `comment` identifies estimates; review them before import. Mealie may not retain the comment during import. Missing yield, timings, categories and tags are allowed and can be added on the review screen.

Duration fields are constrained to a single ISO 8601 time value, such as `PT1H30M`. Ollama is instructed to convert fractional hours and days and use the upper bound of source ranges (6–7 hours becomes `PT7H`), retaining the original range in the instructions and explaining the choice in the metadata note. If a model still returns a pair such as `PT6H-PT7H`, the app uses the upper bound and adds a note. Reversed ranges and other malformed values fail validation. Core checks cover the schema constraints and range handling; live model compliance still needs a smoke test.

## Recipe QA safeguards

Valid JSON alone does not establish recipe accuracy. Changes included in release candidate 0.3.1-rc.2 extend source preservation to nested Markdown ingredient groups, plain ingredient lines, bulleted/numbered steps, blank-line-separated method paragraphs and indented continuation lines. Ingredient group names prefix each member (for example `Lamb Layer: 1kg / 2.2lb Minced/Ground Lamb`), preserving context in Mealie's flat ingredient list. Notes, Equipment and Nutrition headings end recipe sections. Source Notes/Storage/Tips text is preserved in the exported `comment` and review notes; Equipment and Nutrition content is excluded. Bold/italic/list markup and HTML character entities are normalised without changing quantities or cooking wording.

Explicit recipe sections with missing entries or repeated Ingredients headings still block conversion. Bullets are optional: plain ingredient lines at the same indentation are separate entries, while deeper-indented lines continue the preceding entry if no blank line intervenes. Plain method paragraphs separated by blank lines become steps; consecutive unmarked lines form one paragraph. Bulleted/numbered steps continue to work. Unknown headings inside plain-text sections may be treated as content, so review boundaries and the QA summary; the parser does not certify arbitrary website copies. Subsection headings must be Markdown headings, end in a colon or use `For the …`/`… Layer` wording. Inputs without explicit sections still use model extraction and are labelled unverified; arbitrary website copies are not guaranteed to parse correctly.

Recognised source ingredients and instructions replace model arrays, preventing lost ingredients, altered quantities and omitted preheating/cooking options in that path. This bypasses cookbook rewriting. Labelled prep/cook/total times, including website-style `Prep Time25 minutes`, and labelled servings/yield take precedence over model values. The original cooking options remain in the method. For missing cook-time metadata only, a source LOW hours/minutes range uses its upper bound. An impossible estimated total is replaced with a disclosed prep-plus-cook estimate; an impossible explicitly supplied total blocks conversion for review. Missing prep estimates and other generated values remain unverified.

Model-written metadata explanations are discarded. Review notes are generated by application checks, followed by clearly marked source notes. Descriptions must be source quotations or empty; detected conflicting dietary descriptions are removed. The sidebar shows a separate QA SUMMARY with preserved entry counts, source time-field count and removed selections, or an explicit unstructured-content warning. This is not certification of recipe accuracy or dietary suitability. Mealie may not retain exported comments.

`sourceValidation` in `Recipe.Classification.json` gates non-main-course categories, dish-type tags and planning tags. Quick uses final total time. Appliance tags require positive evidence in the parsed source method, not equipment listings; known negated appliance mentions are withheld. Without a parsed method, these appliance tags are withheld. Checks only remove unsupported selections; they never force a category or tag. Keyword/pattern gates can withhold legitimate labels or accept incidental words, and unstructured prose remains unverified.

Reproduce the reported chicken curry case and deliberately corrupted model responses with:

```powershell
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1
powershell.exe -NoProfile -File .\Test-SourceQa.ps1
# Optional: run the same recipe against every installed model on localhost.
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1 -Live
powershell.exe -NoProfile -File .\Test-SourceQa.ps1 -Live
```

The steak pie fixture `Tests/steak-pie.txt` checks ten plain ingredient lines and seven unnumbered method paragraphs, including temperature, fractional cooking range, equal-indentation boundaries and `Serves 4`. Both indented and unindented copies are tested. Approximate timings such as “less than 30 mins” and “over 2 hours” are not parsed as exact source durations; metadata still needs estimation and review.

The curry fixture is `Tests/slow-cooker-chicken-curry.txt`. `Test-SourceQa.ps1` adds a shepherd’s pie regression fixture in `Tests/shepherds-pie.txt`, with 21 ingredients, six steps, all three source durations, yield, preheating, ingredient groups and source notes. It tests corrupted/empty model arrays, invented explanations, equipment-only and negated appliance mentions, indented continuations and blocked ambiguous input. Automated checks cover all 12 ingredients, all five steps, LOW/HIGH ranges, final spinach timing, yield, time consistency, invented descriptions, dietary conflicts, unrelated dessert/baking categories, unsupported planning tags and positive evidence controls. Live QA also checks protected facts and known bad labels; it does not assess the quality of every remaining tag or estimated time. No repair request to another AI model is used as proof of correctness.

Live source-mode check on 2026-11-14: `Test-SourceQa.ps1 -Live` passed protected-fact and known-bad-tag assertions with both `llama3.2:latest` and `qwen2.5:7b` for the shepherd’s pie fixture: all 21 ingredients, six steps, supplied durations and yield were retained. This does not certify every classification selection or a Mealie import.

Historical live check on 2026-11-13, before the latest Unreleased safeguards: both `llama3.2:latest` and `qwen2.5:7b` passed the protected-source and known-bad-label assertions. This was not an overall recipe-quality pass: Llama estimated 90 minutes of prep, while Qwen estimated zero. Those prep estimates remain unverified and demonstrate why review is still required; the app now explicitly marks structured-source prep estimates when no labelled prep duration exists. Missing relevant tags are also possible (Qwen selected only Slow cooker). The source-lock path preserves the original “whole bag of spinach” wording rather than automatically expanding it to 200g.


## Recipe categories and tags

Ollama selects categories and tags from the approved lists in `Recipe.Classification.json`. This single configuration contains the allowed labels and selection rules, and supplies both the structured-output schema and response validation. The preview displays selected categories and tags. JSON exports use `recipeCategory` and `keywords`; enable category/tag inclusion in Mealie's import options to retain them. Import behaviour has been checked against upstream code but still needs a smoke test against your Mealie installation.

The app normalises label casing to the configured spelling and removes duplicates. Unknown labels, invalid arrays and more than two distinct categories fail conversion rather than silently creating new entries. Empty lists are allowed when nothing applies. Offline mode exports empty lists and does not infer classification.

Dietary tags describe the entire recipe as written, including optional ingredients, stocks, sauces and garnishes. Vegetarian excludes meat and fish; Vegan additionally excludes eggs, dairy and honey. Vegan recipes can have both tags. Ollama must withhold dietary tags when ingredients are ambiguous rather than assume substitutions. Configured dietary checks remove Vegetarian/Vegan when conflicting meat/fish tags or ingredient terms are present, and remove Vegan for eggs, dairy or honey, adding a preview/export note. These checks only remove tags; they do not establish dietary suitability. Ingredient matching is deliberately conservative: names such as coconut milk, peanut butter or vegan chicken may also cause a dietary tag to be withheld. Review the result; compound ingredients and unrecognised names still depend on model judgement. `Test-Core.ps1` covers conflicting tags, stocks, fish, eggs, milk, honey, gelatine and retention of supported plant-only selections.

See [RECIPE-CLASSIFICATION.md](RECIPE-CLASSIFICATION.md) for the list guide and examples. Edit `Recipe.Classification.json` to change the allowed choices or rules, then restart the app. Keep names non-empty and unique, with at least one category and tag available. The EXE embeds this configuration at build time; rebuild a new release to distribute changed choices. No separate configuration file is required beside the EXE.

Required tools are not yet generated. Planned tools support, a configuration editor and other follow-on work are tracked in [FUTURE-DEVELOPMENTS.md](FUTURE-DEVELOPMENTS.md).

## Validation and executable build

The app version appears in the bottom-left corner. Its source is `$script:AppVersion` in `Recipe.Core.ps1`; the EXE build derives numeric Windows file metadata from its MAJOR.MINOR.PATCH components with an additional `.0`. Prerelease suffixes appear in the footer and filenames, not the numeric Windows metadata.

```powershell
powershell.exe -NoProfile -File .\Test-Core.ps1
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1
powershell.exe -NoProfile -STA -File .\Test-Gui.ps1
Install-Module ps2exe -Scope CurrentUser
.\Build.ps1
```

The build embeds the conversion core into a single script and produces `dist\MealieJsonCreate-MAJOR.MINOR.PATCH.exe` with STA and no console. WPF and its styles remain embedded in the executable. PS2EXE is a separate build prerequisite; Ollama is a required runtime dependency for the interface. The application does not install dependencies automatically. Executable packaging requires testing in your environment. The GUI test uses mock discovery and generation to check mandatory AI selection, progress, conversion, failure handling, sidebar chips, Back navigation, preserved input, export states and compact layouts. Core checks separately exercise real conversion logic with mocked Ollama responses; live source-mode checks against both installed models are recorded above. Built-EXE conversion and Mealie import still need a manual end-to-end smoke test. Add `-Snapshots` to render visual QA PNGs into `.qa`.

References: [Mealie import implementation](https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/routes/recipe/recipe_crud_routes.py), [Ollama structured outputs](https://docs.ollama.com/capabilities/structured-outputs), [PS2EXE](https://github.com/MScholtes/PS2EXE).

## Installation and updates (Unreleased)

The source now supports an Inno Setup installer alongside the portable EXE. No installer release has been built or upgrade-tested yet. Existing published EXEs do not gain this feature automatically; download the first installer release manually.

Install Inno Setup on the build machine (free for non-commercial use; commercial users are requested to purchase a licence). After preparing a new release version and dated changelog entry, run:

```powershell
.\Build.ps1 -Installer
# If the compiler is elsewhere:
.\Build.ps1 -Installer -IsccPath 'C:\path\to\ISCC.exe'
powershell.exe -NoProfile -File .\Test-Update.ps1
```

Publish both `MealieJsonCreate-VERSION.exe` and `MealieJsonCreate-VERSION-Setup.exe` from `dist/` on the matching GitHub Release. The installer uses a fixed application identity, installs machine-wide under the Windows Program Files location in `Mealie JSON Create`, maintains a Start menu shortcut, offers a desktop shortcut and registers an uninstaller. The exact Program Files variant follows the installer architecture. Versioned installed EXEs are replaced during upgrades and shortcuts target the new version. Installation and updates require administrator approval; ordinary app use does not. Ollama remains a separate dependency. Portable copies outside the installation folder remain separate.

The app checks `tmr2000/Mealie-JSON-Create` on GitHub in the background at launch, in both source and packaged runs. The green header button is hidden while checking, when up to date and if checking fails. It appears at the top-right as **Update available** only when a newer eligible installer is found, with the version in its tooltip, and remains available on both recipe screens. Click it to download; its label changes to **Downloading update...** and then **Install update**. Download failures leave the available-update button visible for retry. Checks send no recipe content or credentials and never block conversion. A failed launch check is retried on the next launch. Only newer stable versions are offered; a final release can replace its same-version release candidate. There is no prerelease channel yet; another RC will not be offered, so end-to-end update testing needs an eligible stable release. GUI checks mock discovery and cover hidden/no-update, found-update and failed-check states.

Click **Update available** to download, then **Install update** to launch the interactive installer. Only an exactly named installer from the matching repository/tag with a GitHub SHA-256 digest and matching size is accepted; the hash is checked again before launch. This verifies the GitHub download, not independent publisher identity; binaries are not code-signed. Save/copy your recipe first: after explicit confirmation and successful elevation the app closes, and unsaved work is discarded. Cancelled elevation leaves the app open. Setup offers to launch the app when finished. A portable EXE uses this same installer flow rather than replacing itself in place. Completed installers remain in a unique Windows temporary folder for normal temp cleanup.

Validation: `Test-Update.ps1` checks version/RC comparisons, rejected prereleases/downgrades, asset URL/digest checks and download integrity with mocked transport. Before publishing, compile the installer and manually test clean installation, standard-user launch, upgrade/shortcut replacement, uninstall, offline checking, cancelled UAC and a real GitHub download. These installation/end-to-end checks are still outstanding. This capability warrants a minor release; AppVersion remains unchanged until a release is requested.

## Application icon

The orange bowl icon in `Assets/MealieJsonCreate.ico` is used for the window and the built EXE. Commit the Assets folder alongside the source. `Build.ps1` embeds the icon, so distributing the EXE does not require this folder. To regenerate its seven sizes (16ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ256 px) from the original vector artwork:

```powershell
powershell.exe -NoProfile -STA -File .\Assets\Generate-Icon.ps1
```

Rebuild with `.\Build.ps1` after changing the icon. Windows may cache an older EXE icon; a newly created shortcut or a different EXE filename can help verify the updated artwork.

## Versioning and releases

Use MAJOR.MINOR.PATCH, for example 0.2.4. See [CHANGELOG.md](CHANGELOG.md) for release history.

| Change | Version increment | Example |
|---|---|---|
| Bug fixes, visual polish, documentation or build fixes without new user capabilities | Patch | 0.2.4 to 0.2.5 |
| New compatible capabilities, such as website import or an additional AI provider | Minor; reset patch | 0.2.4 to 0.3.0 |
| Breaking changes after the stable release, such as incompatible saved settings or a changed export contract | Major; reset minor and patch | 1.4.2 to 2.0.0 |

During 0.x development, use a minor bump for breaking changes and document them explicitly. Move to 1.0.0 once the core paste/convert/review/export workflow, Windows EXE distribution and documented compatibility commitments are stable and tested. A redesign alone does not require a major version.

The compatibility commitments cover documented inputs, Mealie-compatible exports, saved configuration (if introduced), and supported Windows/PowerShell requirements. Changes that force users to alter a documented workflow or migrate data need a compatibility review.

For each release:

1. Review and update README.md alongside affected behaviour, setup, examples and limitations. Keep user-facing change notes under Unreleased as development proceeds, and assess the version impact. Leave AppVersion unchanged until a release is requested.
2. Choose the release version, update AppVersion in Recipe.Core.ps1, and promote the notes to a dated changelog section. Do not change an already published version.
3. Run the relevant checks and Build.ps1. The build requires a matching dated changelog entry and names both the EXE and bundled script using AppVersion. Windows file metadata uses the numeric base version with a trailing .0.
4. Smoke-test the built EXE, then commit source and changelog, tag vMAJOR.MINOR.PATCH and attach the versioned EXE to the matching GitHub Release. Keep dist/ and .qa/ ignored.

Release candidates use MAJOR.MINOR.PATCH-rc.N, starting at rc.1 (for example 0.3.1-rc.1). Increment N for each new candidate, then remove the suffix for the final release. The footer, dated changelog and EXE/bundled-script filenames include the complete candidate version. Windows file metadata uses the base version plus .0 (0.3.1.0 for every 0.3.1 candidate and final); use the filename and app footer to distinguish candidates. Mark GitHub candidate releases as prereleases. Other suffixes such as -beta.1 are not supported. Builds do not invent changelog notes or increase the version automatically.

## Automated GitHub releases (Unreleased)

If Actions shows no runs after a release push, first check Settings > Actions > General allows workflows, and confirm the version tag exists on GitHub. The workflow also supports a manual retry: commit/push the workflow to the default branch, open Actions > Release > Run workflow, select the default branch and enter the existing tag (for example `v0.4.0-rc.1`). Manual runs check out that exact tag rather than building the latest branch; they enforce the same version/notes checks and refuse to overwrite an existing release. A manual run can publish a release, so only start it for a tag you intend to distribute. Enabling Actions after a tag push does not replay that push automatically. Do not recreate or force-push a release tag to trigger a build.

The `Release` GitHub Actions workflow builds on Windows PowerShell 5.1 when a `v*` tag is pushed. It verifies the tag equals AppVersion and extracts only that version's dated CHANGELOG.md section, runs core/update/release-metadata/recipe/source/WPF checks without requiring Ollama, installs PS2EXE 1.0.18 and Inno Setup, and builds both versioned EXEs. It retains the outputs as workflow artifacts, uploads both EXEs into a draft, then publishes using the extracted notes. Release candidates are prereleases and never marked latest; stable releases are marked latest. Existing releases are rejected rather than overwritten. The first hosted run and installer smoke tests remain outstanding; automated GUI checks do not replace a manual packaged-app/installer test.

One-time setup: commit the workflow and scripts to this repository, enable GitHub Actions if disabled, and allow the workflow's `contents: write` permission under repository/organisation policies. The supplied `GITHUB_TOKEN` handles release publishing; no personal token or locally installed Inno Setup is needed for hosted builds. Your local Git authentication must allow pushing code/tags and adding workflow files. The runner installs Inno Setup through Chocolatey, so its resolved version can change; PS2EXE is pinned and the Windows runner image is maintained by GitHub. Current builds are unsigned.

When ready to release:

The recommended route is the reusable interactive wizard:

```powershell
powershell.exe -NoProfile -File .\Release.ps1
# Supply a version explicitly:
powershell.exe -NoProfile -File .\Release.ps1 -Version 0.4.0-rc.1
# Prepare and test offline without staging, committing, tagging or pushing:
powershell.exe -NoProfile -File .\Release.ps1 -Version 0.4.0-rc.1 -PrepareOnly
```

The wizard prompts for a version (suggestions are not automatic policy decisions), verifies it is not older than AppVersion or an existing release/tag, promotes the existing Unreleased notes into a London-dated section, removes the development-only version-impact bullet, updates AppVersion and README's current-release line, and runs all seven local check scripts. Add meaningful Unreleased notes before starting. It does not invent a description of changes, build locally, install dependencies, change Actions settings or download the finished installer. Git and Windows PowerShell 5.1 are local prerequisites; Git push access and enabled GitHub Actions are required for publication. Use the first installer RC to complete manual validation.

After checks pass it prints the release notes, Git file status and diff summary. Review the actual files in your editor/GitHub Desktop, then type the exact `RELEASE VERSION` phrase to proceed. **This stages every changed/untracked non-ignored file and deletion**, commits when necessary, and calls Send-Release.ps1 to push the branch/tag and trigger automatic public publication. Remove unrelated changes before confirming. Any other response leaves prepared files for review with no commit/tag/push. Prepare-only mode never asks to publish or accesses remote tags. Rerun with the same explicit `-Version` to resume an unpublished prepared release with an empty Unreleased section. Existing local/remote tags stop the wizard; inspect a prior failed push before retrying. Test failures stop before staging, and no automatic reset or rollback discards work. Commit hooks or push failures may leave a commit/local tag to inspect.

The wizard and helpers are covered by `Test-ReleaseWizard.ps1` (versions, note promotion, historical preservation, resume and failure before writes), alongside `Test-Release.ps1`. Source AppVersion stays unchanged until you actually run preparation; a script being added is not itself a published release.

To finalise candidates, supply their stable base version (for example `-Version 0.4.0` after `0.4.0-rc.2`). The wizard includes the notes from every dated candidate section for that base version, alongside any Unreleased changes, preserving the original candidate sections. Other new versions require meaningful Unreleased notes.

For manual control instead:

1. Choose a new version under the policy above. Update AppVersion, move completed Unreleased notes into a dated version section, leave an Unreleased heading, and update README's current release text. Use a new RC first when installer testing remains outstanding.
2. Review changes and commit the intended files using Git/GitHub Desktop. `Send-Release.ps1` requires a clean working tree and never automatically stages unrelated files or creates a commit.
3. Run `powershell.exe -NoProfile -File .\Send-Release.ps1 -DryRun` to validate the release and preview the push. This reads remote tags but does not push or create a tag.
4. Run `powershell.exe -NoProfile -File .\Send-Release.ps1`. This creates the annotated tag from AppVersion and atomically pushes the current branch and that tag to origin. **This command authorises automatic public release publication if hosted checks/builds pass.** Normal branch pushes without a version tag do not release anything.
5. Follow the [Release workflow](https://github.com/tmr2000/Mealie-JSON-Create/actions), then download and smoke-test the installer/EXE. The first installer must be downloaded manually; subsequent stable installer releases can be offered by the app updater.

The helper rejects dirty trees, detached HEADs and existing local/remote version tags. Branch protections may require merging through a PR first; check out the resulting release commit on the permitted branch before tagging/pushing. A failed atomic push leaves the local tag for inspection. If a hosted run fails before creating a release, fix infrastructure and rerun that run when appropriate; source changes require a new commit and version/tag. If a failed upload/publication leaves a draft, inspect and complete or remove that unpublished draft before rerunning. Never delete or replace a published release to retry a build. `Get-ReleaseMetadata.ps1` and `Test-Release.ps1` can be run locally to check notes/tag matching; the helper itself has not performed a real push in this change. The hosted workflow does not choose versions or promote notes; Release.ps1 prepares those locally.

## Editing recipe details before export

On the review screen, use the **pencil icon** beside Yield, Timing, Categories or Tags to replace the main content area with a themed editor for that section and add, clear or correct its values. No additional window opens; categories and tags use dark checkboxes with orange checked states and keyboard focus indicators. The former Edit details tab has been removed. Enter yield as text and times as non-negative minutes (decimals allowed); blank means unknown and zero means no time. Select up to two categories and any applicable tags from the approved configuration. Click **Apply changes** to update the displayed recipe and JSON, or **Cancel** to discard the draft. Copy/Save, Back and other sidebar edits are disabled while any editor is open; invalid edits keep the last applied JSON and display an error inside the editor. Total time, when supplied, must be at least as long as each supplied prep/cook time. Manual classification selections are deliberate overrides and are not run through AI evidence gates. Existing source/AI review notes remain historical conversion notes, not validation of manual edits. Back retains applied edits until another conversion replaces the result.

Missing, null or empty Ollama yield, time, category and tag fields no longer block conversion. Missing yield/times export as empty strings and missing classifications as empty arrays. Recognised source values still take precedence. Invalid non-empty durations, unknown classification labels, incorrect field types and recipe-content failures still block conversion. Missing total time cannot qualify a recipe for Quick. The offline parser also leaves unknown yield blank. Mealie import of blank metadata still requires a smoke test.

Validation: `Test-Core.ps1` covers missing/absent/null metadata; `Test-Gui.ps1` covers applying manual edits, clearing time, pending-export protection and invalid edit handling. This is an unreleased compatible capability (minor version impact); AppVersion remains unchanged until a release is requested.

### Editing ingredients and method

The **Ingredients** tab shows the ingredient list; the **Recipe** tab shows the title, description and method. Both ingredient and method sections have pencil buttons. Editing replaces the main content area with one themed text field per ingredient or numbered method step. Use **Add ingredient** / **Add step** or **Remove** to change the list. Newlines within a method field remain part of that step; blank-line separators are no longer needed. **Apply changes** replaces that section in the displayed recipe and export JSON; **Cancel** discards the draft and returns to the selected tab. At least one non-empty ingredient and method step is required, and blank rows must be filled or removed before applying. Group prefixes in ingredient text remain editable text. Manual wording is preserved without AI rewriting or sentence normalisation. Other recipe fields are retained; method steps are exported as HowToStep objects.

Content edits add a review note that source QA counts describe the original conversion. Categories, tags and timings are retained for manual review rather than automatically recalculated. Title and description editing are not implemented. Test-Gui.ps1 covers pencil controls, inline apply/cancel with no owned windows, themed checkbox templates, separate tabs, individual ingredient/method rows, add/remove, multiline step preservation, blank-entry rejection and minimum-size editor layout. Add -Snapshots to render these states into .qa/. These are Unreleased changes with minor version impact for the new ingredient/method editing capability; AppVersion remains 0.4.0 and no published package is replaced.

An evidence-based tagging redesign is proposed in FUTURE-DEVELOPMENTS.md; it is not implemented. Existing Ollama selection and configuration validation remain in use.
