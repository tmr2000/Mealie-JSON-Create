# Recipe corpus

The manifest contains independent expected ingredients, method steps and supplied metadata for three sourced recipes, four deliberately untidy generated recipes and one generated incomplete-input rejection case.

## Source provenance

Retrieved through the web reader on 2026-11-15. These are compact, attributed recipe-card adaptations. Ingredient quantities and cooking facts come from the listed pages. Instructions are condensed and paraphrased, and heading/metadata formatting was adapted for testing. These files are not full HTML snapshots or exact copies of the authors' prose.

| Fixture | Author / site | Source |
|---|---|---|
| web-goodfood-eggs | Bill Granger / Good Food | https://www.bbcgoodfood.com/recipes/perfect-scrambled-eggs-recipe |
| web-budgetbytes-rice | Beth Moncel / Budget Bytes | https://www.budgetbytes.com/simple-sesame-rice/ |
| web-jamie-carrots | Jamie Oliver | https://www.jamieoliver.com/recipes/vegetables/the-best-whole-baked-carrots/ |

## Generated fixtures

- Shopping-list lentils with alternating name/quantity lines, shopping controls, image link, numbered actions and a price note.
- Markdown fish recipe with ingredient subgroups, bullets, notes, temperatures and cooking ranges.
- Chat-note couscous with unfamiliar section names, separated quantities and paragraphs that form longer steps.
- Wrapped tofu-noodle text with mixed bullets, indented ingredient continuation and multiline method paragraphs.
- An unfinished soup with an empty explicit Method section, which must be rejected.

The generated recipes are parser test data. Their recipe quality and storage suitability have not been assessed.

## Running

Run `powershell.exe -NoProfile -File .\Test-RecipeCorpus.ps1` from the repository root for deterministic checks. The unfamiliar-layout case uses a hand-written source-reference grouping oracle supplied by the mock. This tests source assembly and validation. Other cases use real parser code with empty mock estimates/classifications.

Run `powershell.exe -NoProfile -File .\Test-RecipeCorpus.ps1 -Live -Model qwen2.5:7b` to exercise actual organisation, metadata and classification requests. `-Endpoint` selects the Ollama server. The runner visits every manifest case, records failures, then exits unsuccessfully if any failed. A rejection only passes the malformed fixture when its expected error matches.

Both modes compare ingredient and method arrays exactly, including order, quantities and cooking ranges. They check supplied metadata, source attribution and approved classification vocabulary. Live estimates and tag completeness still require review.

Reports and per-recipe JSON exports are saved under `.qa/recipe-corpus-offline.json`, `.qa/recipe-corpus-live.json` and `.qa/corpus-MODE-ID.json`. Failed comparisons retain available export JSON for investigation. Test runs use the repository classification configuration and do not load personal GUI settings.

## Recorded run on 2026-11-15

Offline 8/8 passed. Live qwen2.5:7b 7/8 passed. The remaining failure is generated-chat-couscous, where organisation reused source ID L1 after the correction attempt. It remains a positive case that should eventually succeed. The incomplete-input fixture is a separate expected-rejection case. The first run also exposed decimal quantity corruption (1.75 becoming 75), which was fixed and passed on rerun.
