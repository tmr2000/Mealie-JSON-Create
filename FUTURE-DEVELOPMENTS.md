# Future developments

Ideas and follow-on work, not release commitments. Completed features belong in CHANGELOG.md and README.md.

## Classification settings editor

The shared configuration approach is now implemented: `Recipe.Classification.json` contains approved labels and rules used for the Ollama prompt, structured-output schema and validation.

Next, add an in-app editor for categories, tags and their definitions. Validate edits before saving, support restoring defaults, and decide where user settings live for packaged EXEs. Preserve the single source of truth so displayed choices, prompts and validation cannot drift. Consider import/export of list presets. List changes should not silently rename existing entries in Mealie.

## Required tools

Generate required equipment from the recipe using Ollama, independently of the controlled category/tag lists. Agree whether to include everyday knives, bowls and pans or only equipment worth filtering for. Preserve source-specified sizes and capacities, avoid inferring optional appliances as mandatory, and merge duplicate tool names. Verify the correct import representation against Mealie and show tools in the preview before enabling exports.

## Classification review

Improve dietary ingredient recognition to distinguish plant alternatives such as coconut milk, peanut butter and vegan chicken without overlooking mixed ingredients or optional animal products. Current conservative checks may withhold dietary tags for those names.

Allow users to adjust selected categories and tags before copying or saving, using the same allowed lists. Make estimated metadata easy to review alongside selections. Review additions to the vocabulary as the recipe collection grows.

## Import compatibility checks

Smoke-test categories, tags, durations and yield against the user's Mealie version, including its category/tag import options. Retain representative import examples and check tools separately before promising support. Check whether estimation notes survive import and choose a supported notes representation if needed.

## Direct Mealie integration

Explore creating recipes through Mealie's API instead of manually copying JSON. Define server configuration, secure credential storage, import preview and error handling before implementation. Reuse or explicitly create organisers according to user preferences; do not silently rename existing ones.

## Broader recipe fidelity checks

Extend source locking beyond simple bulleted ingredients and numbered single-line method steps. Preserve source-to-output evidence for unstructured recipes, and detect altered quantities, omitted steps and unsupported claims without trusting another model's verdict. Expand the regression corpus with multiline methods, alternatives, subrecipes and legitimate category/planning wording that the current conservative keyword gates withhold. Consider a source comparison view and explicit review of estimated metadata. Current safeguards are documented in README.md; these broader checks remain unimplemented.
