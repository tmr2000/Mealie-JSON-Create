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

## Evidence-based classification proposal (not implemented)

Keep Recipe.Classification.json as the single source for approved categories, tags and rule definitions. Current Ollama selection and removal-only checks remain unchanged while these rules are discussed. Proposed flow:

1. Use parsed ingredients, method, title, source notes and final timings as separately identified evidence. Preserve exact source snippets and scope; generated prose must not establish source facts. Manual content edits would invalidate derived evidence and require an explicit recheck, retaining deliberate manual selections.
2. Evaluate deterministic planning rules directly (Quick from total time, Make ahead and Freezer friendly from affirmative source guidance). Have Ollama propose semantic facts such as serving role, dish identity and central ingredients, with exact evidence references; do not treat model claims or confidence scores as proof.
3. For each candidate approved label, check positive support, ingredient roles, negation, contradictions and ambiguity. Mark supported, needs review or excluded, with a reason. No arbitrary label counts or forced entries; keep the existing maximum of two categories. Suggested labels needing review would not export until accepted. Missing metadata must continue to allow conversion and export.
4. Show supported selections and review suggestions in the editor; let users add/remove approved labels and preserve those overrides on explicit rechecks. Hard output rules (approved vocabulary, max two categories, valid field shapes) still apply.

Example to agree: traditional shepherd's pie with minced lamb and beef stock should qualify for Main courses, Lamb and Pie & tart; beef stock is a supporting ingredient and must not add Beef. Its description explicitly saying British supports British. A total of 110 minutes excludes Quick. Lamb excludes Vegetarian and Vegan. Without advance-preparation or freezing guidance, neither planning tag applies. Current removal-only keyword checks may miss Pie & tart when the text says only shepherd's pie; dish identity needs phrase recognition rather than literal standalone words alone.

Open decisions: whether recognisable dish identity can establish cuisine without explicit source wording; what counts as a central ingredient (stock/garnishes excluded, threshold still to agree); whether Vegetables belongs on mixed meat dishes; how to identify one-pot recipes and optional alternative methods; how to classify ambiguous compound ingredients and suitable plant alternatives; whether estimated totals can select Quick automatically or require review. No new labels, dietary guarantees, required-tools rules or classifier behaviour are introduced by this proposal.
