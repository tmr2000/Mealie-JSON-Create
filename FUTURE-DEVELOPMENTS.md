# Future developments

Ideas and follow-on work, not release commitments. Completed features belong in CHANGELOG.md and README.md.

## Classification settings editor

The shared configuration approach is now implemented: `Recipe.Classification.json` contains approved labels and rules used for the Ollama prompt, structured-output schema and validation.

Next, add an in-app editor for categories, tags and their definitions. Validate edits before saving, support restoring defaults, and decide where user settings live for packaged EXEs. Preserve the single source of truth so displayed choices, prompts and validation cannot drift. Consider import/export of list presets. List changes should not silently rename existing entries in Mealie.

## Required tools

Generate required equipment from the recipe using Ollama, independently of the controlled category/tag lists. Agree whether to include everyday knives, bowls and pans or only equipment worth filtering for. Preserve source-specified sizes and capacities, avoid inferring optional appliances as mandatory, and merge duplicate tool names. Verify the correct import representation against Mealie and show tools in the preview before enabling exports.

## Classification review

Improve dietary ingredient recognition to distinguish plant alternatives such as coconut milk, peanut butter and vegan chicken without overlooking mixed ingredients or optional animal products. Current conservative checks may withhold dietary tags for those names.

The review screen now supports manual yield, timing and approved category/tag edits before export. Review additions to the vocabulary as the recipe collection grows.

## Import compatibility checks

Smoke-test categories, tags, durations and yield against the user's Mealie version, including its category/tag import options. Retain representative import examples and check tools separately before promising support. Check whether estimation notes survive import and choose a supported notes representation if needed.

## Installer follow-on work

The tag-triggered hosted build/release workflow is implemented; its first GitHub run remains unverified. Consider pinning the Inno Setup package version after the initial hosted installer build has been validated.

The reusable release wizard now prepares version/notes/docs and runs local checks before an explicit commit/publish confirmation. Following a hosted run and downloading/testing its installer remain manual; consider optional GitHub CLI integration to watch the run and retrieve artifacts.

Installer packaging and stable-release checks are implemented in source; compiling and manually validating clean install, upgrades, shortcuts, UAC and uninstall remain outstanding before the first installer release. Consider code signing, a prerelease update channel, download progress/cancellation and automatic temporary-installer cleanup. Current implementation and limitations are in README.md.

## Direct Mealie integration

Explore creating recipes through Mealie's API instead of manually copying JSON. Define server configuration, secure credential storage, import preview and error handling before implementation. Reuse or explicitly create organisers according to user preferences; do not silently rename existing ones.

## Broader recipe fidelity checks

Source locking now supports grouped ingredient lists, numbered/bulleted method steps and indented continuation lines, with source timing/yield precedence and fail-closed handling of ambiguous explicit sections. Plain ingredient lines and blank-line-separated method paragraphs are now supported too. Further extend handling of unknown website headings and more complex subrecipes. Preserve source-to-output evidence for unstructured recipes, and detect altered quantities, omitted steps and unsupported claims without trusting another model's verdict. Expand the regression corpus with more complex multiline methods, alternatives, subrecipes and legitimate category/planning wording that the current conservative keyword gates withhold. Consider a source comparison view and explicit review of estimated metadata. Current safeguards are documented in README.md; these broader checks remain unimplemented.
