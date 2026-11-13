# Mealie JSON Create

A Windows PowerShell WPF app for turning pasted recipe text into schema.org Recipe JSON for Mealie's HTML/JSON import. The Mealie-inspired dark theme has warm orange accents, rounded panels and scalable vector artwork. UI resources are embedded; no browser, downloaded fonts or image files are needed.

## Run

Requires Windows and Windows PowerShell 5.1 (included with Windows). From this folder:

```powershell
powershell.exe -NoProfile -STA -File .\MealieJsonCreate.ps1
```

Paste one recipe, optionally supply a title override and source URL in the settings sidebar, then Convert recipe (or Ctrl+Enter). Switch between Recipe preview and JSON tabs to review the ingredients, method and exported JSON. Copy it into Mealie's HTML/JSON recipe import, or save it as UTF-8 JSON. The input panel includes Paste, Clear text and a character count. The window resizes down to 1080 x 700 device-independent pixels, with scrolling for settings and content. Windows PowerShell 5.1 supports the WPF interface; PowerShell 7 is not required.

Review quantities and instructions before import. This is an import document, not a Mealie backup or native database export. No Mealie credentials are needed. Source URL records attribution; the app does not fetch websites.

## Offline mode

Use a title on the first line, Ingredients and Method (or Instructions/Directions) headings, and one ingredient or step per line. Optional description lines go between the title and Ingredients. Serves, Servings or Yield metadata may appear on its own line. Example:

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

## Ollama mode

The model dropdown lists every installed model reported by the selected server's `/api/tags` endpoint, rather than models available for download or a fixed list. Compare it with `ollama list` against the same server. If both show only one model, check whether the other models belong to a different Ollama instance or model directory. The refresh icon immediately to the right of the dropdown reloads this list.

Install and start Ollama separately, download a suitable text model (for example `ollama pull llama3.2`), enable Cookbook rewrite and select an installed model from the dropdown. The default server is http://localhost:11434. The app queries `/api/tags` on opening and after URL edits; Refresh models reloads the list and retains your selection when available. Discovery runs in the background with a ten-second timeout. Empty or unreachable servers show a status message beside the model controls, independently of recipe conversion status. Ollama conversion requires an available model. Mixed website copy or LLM text is sent to the configured endpoint. Localhost keeps generation on your machine; changing the endpoint sends text to that server.

Ollama rewrites terse methods into moderately detailed cookbook-style paragraphs in British English, explaining actions and their purpose when supported by the source. Related actions stay grouped into logical steps. The prompt preserves quantities, preparation notes, timings and cooking alternatives, and forbids invented recipe facts or a method where none was supplied. Simple steps can remain short. Review the result: these are model instructions, not a guarantee of factual preservation.

Generation runs in a background runspace so the GUI remains responsive. Requests time out after 180 seconds. Structured output, temperature zero, seed 42 and a fixed British English prompt improve consistency. Exact model wording is not guaranteed across model/server versions or hardware; review extracted facts. Missing ingredients or instructions cause a validation error rather than an invented recipe. The model is asked to preserve timings, temperatures and quantities in the instruction text; separate duration metadata is not extracted in this version.

## Validation and executable build

The app version appears in the bottom-left corner. Its source is `$script:AppVersion` in `Recipe.Core.ps1`; the EXE build uses the same version with an additional `.0` for Windows file metadata.

```powershell
powershell.exe -NoProfile -File .\Test-Core.ps1
powershell.exe -NoProfile -STA -File .\Test-Gui.ps1
Install-Module ps2exe -Scope CurrentUser
.\Build.ps1
```

The build embeds the conversion core into a single script and produces `dist\MealieJsonCreate-MAJOR.MINOR.PATCH.exe` with STA and no console. WPF and its styles remain embedded in the executable. PS2EXE is a separate build prerequisite; Ollama remains an optional runtime dependency. The application does not install dependencies automatically. Executable packaging requires testing in your environment. The GUI test uses mock model discovery and checks conversion, previews, model states and compact layout. Add `-Snapshots` to render visual QA PNGs into `.qa`.

References: [Mealie import implementation](https://github.com/mealie-recipes/mealie/blob/mealie-next/mealie/routes/recipe/recipe_crud_routes.py), [Ollama structured outputs](https://docs.ollama.com/capabilities/structured-outputs), [PS2EXE](https://github.com/MScholtes/PS2EXE).

## Application icon

The orange bowl icon in `Assets/MealieJsonCreate.ico` is used for the window and the built EXE. Commit the Assets folder alongside the source. `Build.ps1` embeds the icon, so distributing the EXE does not require this folder. To regenerate its seven sizes (16–256 px) from the original vector artwork:

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

1. Keep user-facing change notes under Unreleased as development proceeds.
2. Choose the release version, update AppVersion in Recipe.Core.ps1, and promote the notes to a dated changelog section. Do not change an already published version.
3. Run the relevant checks and Build.ps1. The build requires a matching dated changelog entry and names both the EXE and bundled script using AppVersion. Windows file metadata uses the same version with a trailing .0.
4. Smoke-test the built EXE, then commit source and changelog, tag vMAJOR.MINOR.PATCH and attach the versioned EXE to the matching GitHub Release. Keep dist/ and .qa/ ignored.

The three numeric components are currently supported by the build; prerelease labels such as -beta.1 would require extending version handling first. Builds do not invent changelog notes or increase the version automatically.
