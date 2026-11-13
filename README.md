# Mealie JSON Create

A Windows PowerShell WPF app for turning pasted recipe text into schema.org Recipe JSON for Mealie's HTML/JSON import. The Mealie-inspired dark theme has warm orange accents, rounded panels and scalable vector artwork. UI resources are embedded; no browser, downloaded fonts or image files are needed.

Current local release: **0.3.0** (`MealieJsonCreate-0.3.0.exe`). This minor release adds time/yield metadata, controlled classification, a two-stage interface and recipe QA safeguards. **Ollama is now required by the interface**; the offline parser is available only to scripts. AI estimates still require review.

## Run

Requires Windows and Windows PowerShell 5.1 (included with Windows). From this folder:

```powershell
powershell.exe -NoProfile -STA -File .\MealieJsonCreate.ps1
```

The app uses two stages, each filling the window workspace:

1. **Recipe text:** paste one recipe, optionally supply a title override and source URL in the settings sidebar, select an installed Ollama model, then choose Convert recipe (or Ctrl+Enter). The input panel includes Paste, Clear text and a character count. Ollama is always used; there is no offline toggle.
2. **Review your recipe:** opens immediately with conversion progress, then displays a larger formatted recipe with ingredients and numbered method steps. A scrollable left sidebar contains boxed yield, readable timings, category/tag chips, review notes and the source URL when supplied. Switch between Recipe preview and JSON, then copy into Mealie's HTML/JSON recipe import or save as UTF-8 JSON. Export buttons stay disabled until conversion succeeds.

Use **Back to recipe** to return to stage 1 with your text, title, source URL and model settings preserved. Back also works during conversion; the background request continues, and another conversion cannot start until it finishes. Errors appear in the footer (hover for full details); the review stage directs you back to correct the input or settings. Ctrl+Enter only starts conversion from stage 1.

The window resizes down to 1080 x 700 device-independent pixels, with scrolling for settings, metadata and recipe content. Stages fill the workspace without forcing Windows fullscreen/maximised mode. Windows PowerShell 5.1 supports the WPF interface; PowerShell 7 is not required.

Review quantities and instructions before import. This is an import document, not a Mealie backup or native database export. No Mealie credentials are needed. Source URL records attribution; the app does not fetch websites.

## Core offline parser (not available in the interface)

The deterministic offline parser remains available for scripts and core checks through `ConvertTo-RecipeJson` without `-UseOllama`; the application interface requires Ollama. For this parser, use a title on the first line, Ingredients and Method (or Instructions/Directions) headings, and one ingredient or step per line. Optional description lines go between the title and Ingredients. Serves, Servings or Yield metadata may appear on its own line. Yield text is preserved (for example `12 muffins`). Label durations as `Prep time: 10 minutes`, `Cook time: 1 hour` and `Total time: 1 hour 20 minutes`; ISO 8601 values such as `PT20M` also work. Missing offline durations remain empty and missing yield is shown as `Not specified`, with a preview note. Offline mode cannot estimate missing metadata. Example:

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

Generation runs in a background runspace so the GUI remains responsive. Requests time out after 180 seconds. Structured output, temperature zero, seed 42 and a fixed British English prompt improve consistency. Exact model wording is not guaranteed across model/server versions or hardware; review extracted facts. Missing ingredients or instructions cause a validation error rather than an invented recipe. The model preserves timings, temperatures and quantities in the instruction text and supplies `prepTime`, `cookTime`, `totalTime` (ISO 8601 durations) and `recipeYield` (yield text). It uses source values where supplied and estimates missing metadata from the recipe. Total time includes waits and overlapping tasks. A note in the preview and JSON `comment` identifies estimates; review them before import. Mealie may not retain the comment during import. Ollama output missing required metadata is rejected.

Duration fields are constrained to a single ISO 8601 time value, such as `PT1H30M`. Ollama is instructed to convert fractional hours and days and use the upper bound of source ranges (6–7 hours becomes `PT7H`), retaining the original range in the instructions and explaining the choice in the metadata note. If a model still returns a pair such as `PT6H-PT7H`, the app uses the upper bound and adds a note. Reversed ranges and other malformed values fail validation. Core checks cover the schema constraints and range handling; live model compliance still needs a smoke test.

## Recipe QA safeguards

Valid JSON alone does not establish recipe accuracy. For a clearly structured plain-text or Markdown recipe with an Ingredients heading, one bulleted/numbered ingredient per line, and a Method/Instructions/Directions heading followed by one numbered step per line, the app retains the source ingredient list and method instead of the model's versions. Bold/list formatting is removed, but quantities, alternatives and wording are kept. This deliberately bypasses cookbook rewriting for recognised structured input, with a review note. Continuation paragraphs, unbulleted ingredients and unnumbered methods do not qualify for this source lock and still use model extraction. Review them particularly carefully.

Descriptions must be quoted from the source or empty; generated descriptions are discarded, including contradictory dietary claims detected by the configured ingredient checks. Structured-source yield in numeric `portions`/`servings` form takes precedence over generated yield. For a recognised structured recipe with `LOW for 6–7 hours` (or an equivalent whole-number hours/minutes range), cook time uses the upper LOW bound. The original LOW/HIGH alternatives remain in the method. If total time is less than either prep or cook time, it is replaced with an explicitly noted estimate of prep plus cook; this does not prove that other waits or overlaps were handled correctly. Prep estimates and zero values still require review.

`sourceValidation` in `Recipe.Classification.json` provides conservative evidence gates for non-main-course categories, Make ahead and Freezer friendly; Quick is checked against the final total time. Unsupported selections are removed with notes, not replaced by arbitrary labels. These are keyword/pattern checks, not a complete semantic validator: legitimate selections may be withheld and an incidental keyword may pass. Main courses and other tags still depend on model judgement. The app does not certify that generated prose is correct for unstructured inputs or that every omitted/invented fact has been detected.

Reproduce the reported chicken curry case and deliberately corrupted model responses with:

```powershell
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1
# Optional: run the same recipe against every installed model on localhost.
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1 -Live
```

The fixture is `Tests/slow-cooker-chicken-curry.txt`. Automated checks cover all 12 ingredients, all five steps, LOW/HIGH ranges, final spinach timing, yield, time consistency, invented descriptions, dietary conflicts, unrelated dessert/baking categories, unsupported planning tags and positive evidence controls. Live QA also checks protected facts and known bad labels; it does not assess the quality of every remaining tag or estimated time. No repair request to another AI model is used as proof of correctness.

Live check on 2026-11-13 using this fixture: both `llama3.2:latest` and `qwen2.5:7b` passed the protected-source and known-bad-label assertions. This was not an overall recipe-quality pass: Llama estimated 90 minutes of prep, while Qwen estimated zero. Those prep estimates remain unverified and demonstrate why review is still required; the app now explicitly marks structured-source prep estimates when no labelled prep duration exists. Missing relevant tags are also possible (Qwen selected only Slow cooker). The source-lock path preserves the original “whole bag of spinach” wording rather than automatically expanding it to 200g.


## Recipe categories and tags

Ollama selects categories and tags from the approved lists in `Recipe.Classification.json`. This single configuration contains the allowed labels and selection rules, and supplies both the structured-output schema and response validation. The preview displays selected categories and tags. JSON exports use `recipeCategory` and `keywords`; enable category/tag inclusion in Mealie's import options to retain them. Import behaviour has been checked against upstream code but still needs a smoke test against your Mealie installation.

The app normalises label casing to the configured spelling and removes duplicates. Unknown labels, invalid arrays and more than two distinct categories fail conversion rather than silently creating new entries. Empty lists are allowed when nothing applies. Offline mode exports empty lists and does not infer classification.

Dietary tags describe the entire recipe as written, including optional ingredients, stocks, sauces and garnishes. Vegetarian excludes meat and fish; Vegan additionally excludes eggs, dairy and honey. Vegan recipes can have both tags. Ollama must withhold dietary tags when ingredients are ambiguous rather than assume substitutions. Configured dietary checks remove Vegetarian/Vegan when conflicting meat/fish tags or ingredient terms are present, and remove Vegan for eggs, dairy or honey, adding a preview/export note. These checks only remove tags; they do not establish dietary suitability. Ingredient matching is deliberately conservative: names such as coconut milk, peanut butter or vegan chicken may also cause a dietary tag to be withheld. Review the result; compound ingredients and unrecognised names still depend on model judgement. `Test-Core.ps1` covers conflicting tags, stocks, fish, eggs, milk, honey, gelatine and retention of supported plant-only selections.

See [RECIPE-CLASSIFICATION.md](RECIPE-CLASSIFICATION.md) for the list guide and examples. Edit `Recipe.Classification.json` to change the allowed choices or rules, then restart the app. Keep names non-empty and unique, with at least one category and tag available. The EXE embeds this configuration at build time; rebuild a new release to distribute changed choices. No separate configuration file is required beside the EXE.

Required tools are not yet generated. Planned tools support, a configuration editor and other follow-on work are tracked in [FUTURE-DEVELOPMENTS.md](FUTURE-DEVELOPMENTS.md).

## Validation and executable build

The app version appears in the bottom-left corner. Its source is `$script:AppVersion` in `Recipe.Core.ps1`; the EXE build uses the same version with an additional `.0` for Windows file metadata.

```powershell
powershell.exe -NoProfile -File .\Test-Core.ps1
powershell.exe -NoProfile -File .\Test-RecipeQa.ps1
powershell.exe -NoProfile -STA -File .\Test-Gui.ps1
Install-Module ps2exe -Scope CurrentUser
.\Build.ps1
```

The build embeds the conversion core into a single script and produces `dist\MealieJsonCreate-MAJOR.MINOR.PATCH.exe` with STA and no console. WPF and its styles remain embedded in the executable. PS2EXE is a separate build prerequisite; Ollama is a required runtime dependency for the interface. The application does not install dependencies automatically. Executable packaging requires testing in your environment. The GUI test uses mock discovery and generation to check mandatory AI selection, progress, conversion, failure handling, sidebar chips, Back navigation, preserved input, export states and compact layouts. Core checks separately exercise real conversion logic with mocked Ollama responses; live source-mode checks against both installed models are recorded above. Built-EXE conversion and Mealie import still need a manual end-to-end smoke test. Add `-Snapshots` to render visual QA PNGs into `.qa`.

References: [Mealie import implementation](https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/routes/recipe/recipe_crud_routes.py), [Ollama structured outputs](https://docs.ollama.com/capabilities/structured-outputs), [PS2EXE](https://github.com/MScholtes/PS2EXE).

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
3. Run the relevant checks and Build.ps1. The build requires a matching dated changelog entry and names both the EXE and bundled script using AppVersion. Windows file metadata uses the same version with a trailing .0.
4. Smoke-test the built EXE, then commit source and changelog, tag vMAJOR.MINOR.PATCH and attach the versioned EXE to the matching GitHub Release. Keep dist/ and .qa/ ignored.

The three numeric components are currently supported by the build; prerelease labels such as -beta.1 would require extending version handling first. Builds do not invent changelog notes or increase the version automatically.
