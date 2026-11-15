# Mealie JSON Create

A Windows PowerShell WPF app for turning pasted recipe text into schema.org Recipe JSON for Mealie's HTML/JSON import. The Mealie-inspired dark theme has warm orange accents, rounded panels and scalable vector artwork. UI resources are embedded; no browser, downloaded fonts or image files are needed.

Current release candidate: **0.6.0-rc.1** (`MealieJsonCreate-0.6.0-rc.1.exe`, `MealieJsonCreate-0.6.0-rc.1-Setup.exe`). See CHANGELOG.md for changes. Downloads become available after the release pipeline succeeds.

Previous local release: **0.3.0** (`MealieJsonCreate-0.3.0.exe`). This minor release adds time/yield metadata, controlled classification, a two-stage interface and recipe QA safeguards. **Ollama is now required by the interface**; the offline parser is available only to scripts. AI estimates still require review.

## Run

Requires Windows and Windows PowerShell 5.1 (included with Windows). From this folder:

```powershell
powershell.exe -NoProfile -STA -File .\MealieJsonCreate.ps1
```

The app uses two stages, each filling the window workspace:

1. **Recipe text:** paste one recipe, optionally supply a title override and source URL in the settings sidebar, choose the server/default model under Settings > Local AI, then choose Convert recipe (or Ctrl+Enter). The input panel includes Paste, Clear text and a character count. Ollama is always used; there is no offline toggle.
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

**AI settings (Unreleased):** open the top-bar cog, then **Local AI** to set the Ollama server and **Default model**, or refresh the server's installed models. These controls have moved from the recipe sidebar. The server can be local or on your network; Ollama does not need to be installed on this computer and the installer has no Ollama prerequisite. Choose **Save settings** to persist the endpoint and selected default in `%LOCALAPPDATA%\MealieJsonCreate\ai-settings.json` for future launches. Cancel restores the server/model choices from when Settings opened. Classification settings remain in the Tags and Categories tabs.

Startup discovers models from the saved server and selects the saved model when available. Otherwise it selects the first available model and reports that the previous/default model is unavailable. An empty or unreachable server prevents conversion; use Settings to correct it. Saving unrelated settings while that same server is unavailable retains its saved default. Discovery must finish before saving. Invalid saved settings report an error and use the localhost defaults. Model selection is saved only with **Save settings**. Validation: `Test-Gui.ps1` covers AI controls in Settings, endpoint/model file round-trip and loading, alongside model discovery, refresh, unavailable servers and conversion. This is an Unreleased minor capability; AppVersion remains 0.5.0.

The model dropdown in Settings lists every installed model reported by the selected server's `/api/tags` endpoint, rather than models available for download or a fixed list. Compare it with `ollama list` against the same server. If both show only one model, check whether the other models belong to a different Ollama instance or model directory. The refresh icon immediately to the right of the dropdown reloads this list.

Use a running local or network Ollama server with a suitable text model. For local setup, install/start Ollama and download a model (for example `ollama pull llama3.2`); select it in Settings > Local AI. The default server is http://localhost:11434. The app queries `/api/tags` on opening and after URL edits; Refresh models reloads the list and retains your selection when available. Discovery runs in the background with a ten-second timeout. Empty or unreachable servers show a status message beside the model controls, independently of recipe conversion status. Ollama conversion requires an available model. Mixed website copy or LLM text is sent to the configured endpoint. Localhost keeps generation on your machine; changing the endpoint sends text to that server.

PowerShell first parses headings, list entries, servings and labelled timings. Recognised sections supply the ingredients and steps directly. For unfamiliar layouts, an organisation request assigns source-line IDs to title, description, ingredient groups, method groups, notes and ignored content. The app assembles the original wording. Standalone Markdown links and shopping controls are removed first. The organiser can combine split names/quantities and step headings/paragraphs. Every remaining line must be accounted for exactly once, including ignored lines. Unknown, reused or missing IDs trigger one correction request, followed by a review error if still invalid. Model decisions to group or ignore content still require manual review. Ambiguous explicit sections still produce a review error. For structured recipes the first introduction line supplies the title and a following sentence may supply the description.

Only missing yield or duration fields trigger an estimation request. A separate classification request receives structured entries with ingredient and step IDs, category descriptions and approved tag groups. Evidence references resolve locally to their source text. Local rules validate the selections and assemble the export. A fully labelled structured recipe uses one request, and unstructured text with missing metadata can use three. Each request has a 180-second timeout. Optional request failures are recorded in review notes. Standard export formatting still normalises whitespace and sentence punctuation.

## Recipe QA safeguards

Valid JSON alone does not establish recipe accuracy. Changes included in release candidate 0.3.1-rc.2 extend source preservation to nested Markdown ingredient groups, plain ingredient lines, bulleted/numbered steps, blank-line-separated method paragraphs and indented continuation lines. Ingredient group names prefix each member (for example `Lamb Layer: 1kg / 2.2lb Minced/Ground Lamb`), preserving context in Mealie's flat ingredient list. Notes, Equipment and Nutrition headings end recipe sections. Source Notes/Storage/Tips text is preserved in the exported `comment` and review notes; Equipment and Nutrition content is excluded. Bold/italic/list markup and HTML character entities are normalised without changing quantities or cooking wording.

Explicit recipe sections with missing entries or repeated Ingredients headings still block conversion. Bullets are optional: plain ingredient lines at the same indentation are separate entries, while deeper-indented lines continue the preceding entry if no blank line intervenes. Plain method paragraphs separated by blank lines become steps; consecutive unmarked lines form one paragraph. Bulleted/numbered steps continue to work. Unknown headings inside plain-text sections may be treated as content, so review boundaries and the QA summary; the parser does not certify arbitrary website copies. Subsection headings must be Markdown headings, end in a colon or use `For the …`/`… Layer` wording. Inputs without explicit sections still use model extraction and are labelled unverified; arbitrary website copies are not guaranteed to parse correctly.

Recognised source ingredients and instructions bypass model extraction, preventing lost ingredients, altered quantities and omitted preheating/cooking options in that path. This bypasses cookbook rewriting. Labelled prep/cook/total times, including website-style `Prep Time25 minutes`, and labelled servings/yield take precedence over model values. The original cooking options remain in the method. For missing cook-time metadata only, a source LOW hours/minutes range uses its upper bound. An impossible estimated total is replaced with a disclosed prep-plus-cook estimate; an impossible explicitly supplied total blocks conversion for review. Missing prep estimates and other generated values remain unverified.

Model-written metadata explanations are discarded. Review notes are generated by application checks, followed by clearly marked source notes. Descriptions must be source quotations or empty; detected conflicting dietary descriptions are removed. The sidebar shows a separate QA SUMMARY with preserved entry counts, source time-field count and removed selections, or an explicit unstructured-content warning. This is not certification of recipe accuracy or dietary suitability. Mealie may not retain exported comments.

`sourceValidation` and `evidenceRules` in `Recipe.Classification.json` now drive a first evidence-based classifier (Unreleased). It evaluates every approved label, adding supported labels Ollama missed as well as withholding unsupported suggestions. Dish identities/serving roles use the source title; cuisine and central-ingredient identity use the source introduction, ingredients use parsed ingredient lines, and appliances require parsed method evidence. Pattern matching remains conservative and is not a complete semantic classifier; see the classification section below.

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

Ollama proposes categories/tags and ingredient or method IDs for evidence, then local evidence rules evaluate all approved labels in `Recipe.Classification.json`. This configuration supplies the prompt, schema enums, validation and rule patterns. The Unreleased engine can recover omitted labels: a chicken curry with source chicken and slow-cooker instructions can get Curry, Chicken and Slow cooker even if the model selects none. Rules do not add arbitrary labels or force non-empty arrays. JSON exports still use `recipeCategory` and `keywords`; enable category/tag inclusion in Mealie's import options to retain them. Import against your installation still needs a smoke test.

Each decision has a status (supported, review, excluded), reason, evidence scope and available source excerpt. Approved tag recommendations start checked, with an exception for Vegetarian/Vegan recommendations explicitly contradicted by the ingredients. Those automatic dietary selections are removed. Other uncertain or contradictory recommendations retain their evidence reasons for review. Categories still require support or manual selection. Exact model quotations must occur in the named source scope; a real quotation alone does not prove its interpretation. Invalid/missing optional evidence claims are ignored rather than blocking a recipe. Casing/deduplication and unknown-label/invalid-array rejection remain in place. More than two model categories remains invalid; if rules find several possible serving categories, automatic selections move to review rather than choosing two arbitrarily. Offline mode still exports empty classification arrays.

First-pass choices: cuisine needs explicit introduction wording; dish-type/category rules use title patterns; a central ingredient must appear in both the dish introduction and a parsed non-supporting ingredient line. Stocks, sauces, garnishes and accompaniments cannot establish a main ingredient tag. An ingredient present without a clear central role needs review. Vegetables remains a review suggestion rather than an automatic addition to mixed dishes. Appliance alternatives need review; equipment-only/negated mentions do not qualify. One pot/No cook require an explicit introduction claim and no configured contradictory method evidence. Quick requires a source-supplied or manually confirmed total of at most 30 minutes; an estimated qualifying total only suggests Quick for review. Make ahead/Freezer friendly require affirmative source guidance.

Dietary tags describe the entire recipe as written, including optional ingredients. Model dietary suggestions need parsed source ingredients and must pass configured exclusions/ambiguity checks. Known plant alternatives (including coconut milk, peanut butter and vegan chicken) are normalised for matching without altering recipe text. Meat/fish and dairy/egg/honey exclusions still apply; ambiguous cheese, stocks and compound ingredients need review. Vegan also includes Vegetarian unless manually removed. These checks do not certify suitability and do not recognise every product or compound ingredient. Manual selections deliberately override automatic decisions.

Open the category/tag pencil editors to see decision reasons and source excerpts; all approved choices remain available. Use **Recheck classification** in the sidebar after changing ingredients, method or total time. Recheck uses current edited sections and does not call Ollama again; it preserves manual additions/removals. Applying a category/tag editor records the whole displayed field as manual choices, including unchecked labels, until another conversion. Cancel does not record overrides. Content edits mark previous reasons stale and clear old model quotations. Manual edited sections supply current recheck evidence, but originally unstructured content remains unverified for dietary/no-cook checks. Reports and overrides live only in the current result, outside exported schema.org fields; a short review-count note is exported in comment. Rechecking updates that count.

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

The `Release` GitHub Actions workflow builds on Windows PowerShell 5.1 when a `v*` tag is pushed. It verifies the tag equals AppVersion and extracts only that version's dated CHANGELOG.md section, runs core/update/release-metadata/recipe/source/classification/WPF checks without requiring Ollama, installs PS2EXE 1.0.18 and Inno Setup, and builds both versioned EXEs. It retains the outputs as workflow artifacts, uploads both EXEs into a draft, then publishes using the extracted notes. Release candidates are prereleases and never marked latest; stable releases are marked latest. Existing releases are rejected rather than overwritten. The first hosted run and installer smoke tests remain outstanding; automated GUI checks do not replace a manual packaged-app/installer test.

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

Content edits add a review note that source QA counts describe the original conversion. Categories, tags and timings are retained for review rather than automatically recalculated; use Recheck classification to refresh classification decisions while retaining manual choices. Title and description editing are not implemented. Test-Gui.ps1 covers pencil controls, inline apply/cancel with no owned windows, themed checkbox templates, separate tabs, individual ingredient/method rows, add/remove, multiline step preservation, blank-entry rejection and minimum-size editor layout. Add -Snapshots to render these states into .qa/. These are Unreleased changes with minor version impact for the new ingredient/method editing capability; AppVersion remains 0.5.0 and no published package is replaced.

The first evidence-based classification pass is implemented under Unreleased; refinements and open decisions remain in FUTURE-DEVELOPMENTS.md. AppVersion stays 0.5.0 until a new release is requested.

### Classification validation

Run `powershell.exe -NoProfile -File .\Test-Classification.ps1` for missed-label recovery, scoped evidence, stock/central roles, estimated versus explicit Quick, dietary conflicts, plant alternatives, planning negation, optional appliances, invented citations, manual overrides, category limits and the separate report/JSON contract. Test-Gui.ps1 covers evidence display, stale state, rechecks and manual-selection retention. These checks are included in Release.ps1 and hosted release checks. All classification behaviour described above is Unreleased, with minor version impact for the new review/recheck capability; existing 0.5.0 packages are unchanged.

Historical check before tag preselection on 2026-11-15 with qwen2.5:7b and Tests/shepherds-pie.txt: Main courses; British, Pie & tart and Lamb; no Beef tag from beef stock. All 21 ingredients and six steps were retained, with three remaining suggestions held for review. This does not validate other models, every rule or a packaged Mealie import.

## Classification settings (Unreleased)

Open the cog in the top bar and choose Tags or Categories (the Local AI tab configures the server and default model). Use the orange **+ Add tag** or **+ Add category** button above the list to create an entry. Click a name to open its editor below the list. Edit its name and selection instruction, or use Add and Remove. Save settings applies the list to the next conversion. Cancel discards the draft. Names must be unique within each list and both lists need at least one entry. Restarting the app reloads the saved entries into both settings tabs. Settings persist in `%LOCALAPPDATA%\MealieJsonCreate\classification-settings.json`. Existing recipes keep their selections.

Every default tag has its own Ollama selection instruction in Recipe.Classification.json (tagDefinitions). The settings editor displays that individual instruction; the classification request sends the same text alongside the shared group guidance. Editing one tag changes its individual rule. New, renamed or edited labels use the model's selection under that instruction instead of their original local matching heuristics. Untouched labels continue using built-in evidence checks. Approved names constrain the output schema and the manual review choices. Test-Gui.ps1 exercises editing, saving, reading back and removing entries.

Organisation checks run with Test-Organisation.ps1. Tests/burrito-bowls.txt covers the shopping-list layout with 14 ingredients and four steps for live checks.

Copied Shopping list / How to make it layouts are grouped locally before the AI fallback. Split quantity rows and numbered step paragraphs are assembled from source text. Other unfamiliar layouts use the ID organisation request. Live organisation reliability remains dependent on model output and invalid grouping can require manual headings.

## Multi-site and messy-input regression corpus

Tests/corpus/manifest.json defines eight additional cases with independent expected source facts. Three compact recipe-card adaptations are attributed to Good Food, Budget Bytes and Jamie Oliver. Four original generated recipes mix shopping-list controls, split quantities, Markdown ingredient groups, informal headings, wrapped lines and method paragraphs. A fifth generated input checks rejection of incomplete sections. Tests/corpus/README.md records source URLs, retrieval dates and adaptation details.

Run the offline corpus with `powershell.exe -NoProfile -File .\Test-RecipeCorpus.ps1`. Run actual Ollama generation with `powershell.exe -NoProfile -File .\Test-RecipeCorpus.ps1 -Live -Model qwen2.5:7b`. Both modes visit every case and check exact ingredient/step preservation, order, supplied metadata, attribution and classification vocabulary. The offline organiser mock uses hand-written grouping expectations; live mode exercises the model's grouping. Reports and available exports, including failed comparisons, are saved in .qa/. Model estimates and classification completeness still require review. Local and hosted release checks include the offline corpus.

The corpus uncovered numbered-list cleanup stripping the integer part from decimal quantities such as 1.75 cups. Cleanup now requires whitespace or end-of-line after a numeric list marker. This validation/formatting change has patch version impact and remains under Unreleased, with AppVersion unchanged.

Corpus validation on 2026-11-15: all ten deterministic test scripts passed, including 8/8 corpus cases. Live qwen2.5:7b passed 7/8 corpus cases. The chat-note couscous fixture failed after organisation reused source ID L1; this remains a visible failing positive case in the live report. The incomplete-input fixture passes only when rejected as expected. These results cover source preservation and output validity, not the accuracy of estimated timings or tag completeness.

Older settings entries that still contain an unchanged shared group instruction are upgraded to the individual default instruction when loaded. Renamed labels, edited instructions and removed labels are preserved. Save settings persists the upgraded draft. Category instructions remain individually defined by each category description. Test-Gui.ps1 covers selecting different tags, upgrading old defaults and preserving custom instructions; Test-Classification.ps1 checks the instructions in the actual request payload.

Dietary contradiction checks use the recipe as written, including meat stocks and optional animal ingredients. Common configured plant alternatives are normalised for matching. They run on conversion and classification recheck. A deliberate manual checkbox override is preserved; the reason identifies it as manual. Test-Classification.ps1 and Test-RecipeQa.ps1 cover a model returning Vegetarian/Vegan for the chicken curry fixture, and customised dietary rules cannot bypass automatic exclusion.

## Focused tag contradiction check (Unreleased)

After local classification and dietary exclusions, conversion makes one additional Ollama request when there are multiple selected tags or a selected tag with uncertain evidence. The request contains the proposed tags, their individual definitions, the structured recipe with ingredient/method IDs and final total time. The model returns keep/remove/review decisions. Compatible tags such as Chicken with Vegetables and Vegan with Vegetarian are explicitly allowed together.

A removal requires a non-empty reason and at least one existing ingredient/method ID. Repeated, unknown or malformed decisions invalidate the response as a whole. Omitted tags remain selected and receive an explicit review reason. Valid removals update the preview and JSON, with reasons/excerpts in the tag editor. A review decision keeps the tag checked for manual correction. Invalid or failed requests retain local recommendations and add a review note. Existing dietary ingredient exclusions run independently. Evidence IDs establish source references; the model's interpretation can still be wrong.

Local Recheck classification retains accepted model decisions while the underlying recipe is unchanged and preserves manual choices. Editing content or confirming timings clears the previous model decisions; the local recheck uses the changed recipe without another Ollama call. A new conversion performs a fresh model check. Conversion may take one extra request timeout (up to 180 seconds). Test-Classification.ps1 covers compatible tags, evidence-backed removal, invalid-response fallback and manual overrides. This is an Unreleased minor capability; AppVersion remains unchanged.

Live contradiction check on 2026-11-15 with qwen2.5:7b: the normal chicken curry conversion retained compatible Chicken, Curry, Beans & lentils and Slow cooker. In a second run, classification was deliberately mocked to include No cook for a simmered chicken/vegetable stew while the contradiction reviewer used the real model. The reviewer removed No cook with method evidence, retained Chicken and Vegetables, and omitted Quick; the app retained Quick with an explicit review reason. This checks the review stage on a forced contradiction, not every possible model inference.
