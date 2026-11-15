# Recipe categories and tags

These approved lists are used by Ollama conversion. `Recipe.Classification.json` is the authoritative editable configuration for labels and selection rules; this document is the human-readable guide. Update this guide when changing the configuration. Group headings are organisational only.

## Categories

Categories describe how a recipe is served. Choose one primary category, with a second only when clearly useful. Do not classify every main course as Lunch and Dinner; those occasions are deliberately omitted.

| Category | Use for |
|---|---|
| Breakfast & brunch | Breakfast dishes, porridge, breakfast pancakes and cooked breakfasts |
| Starters | Small dishes explicitly served before a main course |
| Main courses | The central dish of a meal, including substantial soups and salads |
| Side dishes | Accompaniments such as vegetables, rice, potatoes and side salads |
| Snacks | Small bites and between-meal food |
| Desserts | Sweet dishes served as a dessert |
| Cakes & baking | Cakes, biscuits, pastries and sweet baked goods |
| Bread & dough | Bread, rolls, flatbreads and dough recipes |
| Sauces & condiments | Sauces, dressings, dips, spreads and seasoning mixes |
| Preserves & pickles | Jams, chutneys, pickles and other preserved preparations |
| Drinks | Smoothies, shakes, hot drinks and other beverages |
| Basics & components | Stocks, fillings and other preparations intended for use in another recipe |

A cake may be Cakes & baking and Desserts if its intended use supports both. A curry served as a meal is Main courses; its Curry tag describes the dish type. Do not add a generic Other category: return an empty list when no category fits.

## Tags

Choose every clearly supported tag that adds useful filtering information, generally no more than eight. This is a relevance target, not a reason to discard a clearly applicable tag. Never invent a tag or infer attributes from the title alone when ingredients or instructions contradict them.

### Cuisine

Use only when the source identifies the cuisine or the recipe has a clear, specific culinary identity. An ingredient alone (such as soy sauce) is insufficient. Omit cuisine when uncertain; this starter list can grow with the collection.

British, Irish, Italian, French, Spanish, Greek, Turkish, Middle Eastern, North African, Indian, Thai, Chinese, Japanese, Korean, Vietnamese, Mexican, American, Caribbean.

### Dish type

These work across serving categories: a soup can be a starter or a main course, for example.

Soup, Stew, Curry, Salad, Pasta, Noodles, Rice dish, Pizza, Pie & tart, Sandwich & wrap, Traybake.

### Main ingredient

Apply when the ingredient is central to the dish, not a garnish, stock or minor seasoning. Several may apply. Seafood means shellfish and other seafood apart from finfish, which uses Fish.

Chicken, Turkey, Beef, Pork, Lamb, Fish, Seafood, Eggs, Beans & lentils, Tofu & tempeh, Vegetables.

### Dietary pattern

Vegetarian, Vegan.

Vegetarian excludes meat, fish, seafood, meat stocks, gelatine and explicitly animal-rennet cheese. Vegan additionally excludes dairy, eggs, honey and other animal-derived ingredients. Apply both Vegetarian and Vegan to vegan recipes so vegetarian filtering also finds them. Withhold these tags if an ambiguous ingredient could change the classification, unless the source specifies a suitable version. Do not silently substitute ingredients to qualify a recipe.

Allergen-free, gluten-free and medical-diet tags are deliberately outside this initial list; ordinary recipe text often lacks the product details needed to establish them reliably.

Check the entire recipe as written, including optional ingredients, stocks, sauces and garnishes. A possible vegetarian adaptation does not qualify the original recipe. Meat/fish ingredient tags cannot coexist with Vegetarian or Vegan, and Eggs cannot coexist with Vegan. For example, chicken curry with vegetables is neither Vegetarian nor Vegan; an egg dish may be Vegetarian but is not Vegan.

The configuration's `dietaryValidation` exclusions and `evidenceRules` now evaluate parsed ingredients, ignoring configured plant-alternative phrases during matching. Model dietary selections can be supported only with a parsed ingredient list, no recognised conflict and no configured ambiguity. Coconut milk, peanut butter, vegan chicken and explicitly vegetable/vegetarian stock are recognised alternatives; the recipe text is never changed. Ambiguous compounds still need review and these checks are not dietary certification.

### Method

Apply only when the recipe actually uses the method. A tool tag is useful for filtering even though the same appliance may also appear under Required tools.

One pot, Air fryer, Slow cooker, Pressure cooker, Barbecue, No cook.

One pot means one cooking vessel; a mixing bowl does not disqualify it. No cook means no heat is required anywhere in the method. Use Traybake from Dish type for food cooked together on a baking tray.

### Planning

Quick (30 minutes or less), Make ahead, Freezer friendly.

Quick requires total elapsed time of at most 30 minutes, including waits. The first evidence pass auto-selects it only for source-supplied or manually confirmed totals; an estimated qualifying total is a review suggestion. Make ahead requires source guidance on preparing in advance. Freezer friendly requires explicit source freezing guidance; do not guess storage suitability or invent storage instructions.

## Selection examples

Illustrative only; actual tags depend on the supplied ingredients and method.

| Recipe | Categories | Tags |
|---|---|---|
| Italian tomato pasta, 25 minutes, explicitly vegan | Main courses | Italian; Pasta; Vegetables; Vegetarian; Vegan; Quick (30 minutes or less) |
| Slow-cooker beef stew | Main courses | Stew; Beef; Slow cooker |
| Hummus with a clearly vegan ingredient list | Sauces & condiments | Beans & lentils; Vegetarian; Vegan; No cook |
| Apple crumble served as pudding | Desserts | No tag required if none of the allowed values fits |

## Evidence decisions (Unreleased)

Evidence ratings describe the strength of a recommendation. Recommended tags start checked, except automatic Vegetarian/Vegan selections contradicted by ingredients. This exclusion also applies to customised dietary prompts. The checkbox controls export. Manual removals persist on recheck.

`Recipe.Classification.json` remains authoritative for labels, definitions, prompt rules and executable evidence patterns. Approved lists are unchanged. `sourceValidation` contains identity/appliance/planning patterns and `evidenceRules` contains role exclusions, alternative-ingredient normalisation, ambiguity, negation and identity rules. The engine evaluates all approved labels, not only Ollama's choices.

| Group | First-pass automatic support |
|---|---|
| Categories | Source title matches a configured serving/dish identity pattern; multiple ambiguous categories move to review rather than forcing a choice |
| Cuisine | Explicit cuisine wording in source introduction; inferred culinary identity remains a review suggestion |
| Dish type | Source title matches its dish-type pattern; incidental ingredients/method words do not establish the whole dish type |
| Main ingredient | Named in source introduction and present in a parsed ingredient line, excluding configured stocks/sauces/garnishes/accompaniments; ingredient presence alone needs review |
| Dietary | Model selection plus parsed source ingredients with no configured conflicts or ambiguity; Vegan also supplies Vegetarian unless manually removed |
| Appliances | Positive parsed-method use; equipment-only/negated mentions are excluded and alternatives need review |
| One pot / No cook | Explicit introduction claim with parsed method and no configured vessel/heating contradiction |
| Planning | Affirmative source guidance; Quick requires source/manual total, with estimated qualifying totals held for review |

Vegetables remains a manual/review decision. Matching is deliberately conservative: a central ingredient in a sauce-containing line can be withheld, synonyms can be missed, introduction words can be incidental, and vessel/negation patterns are incomplete. The examples above illustrate intended classification, not a guarantee that every label is automatically selected by this first pass.

Each approved label receives supported, review or excluded status, a reason and available scoped source evidence. Source quotations resolved from model ingredient/method IDs are checked against their named scope; invented/malformed claims are ignored and correct quotes do not prove the inference. Recommended tags start checked even with weak or conflicting evidence. Categories needing review require manual selection. Manual overrides may contradict automatic suggestions and are explicitly identified as manual decisions. Unknown labels and invalid arrays are rejected; empty selections are valid.

The category/tag pencil editors display relevant reasons and snippets, with tooltips on choices. Sidebar Recheck classification uses current content and final total without another model request, retaining manual choices. Applying a category/tag field records all its checkbox choices until the next conversion; cancelling records none. Content/total changes mark evidence stale; content changes clear old quotations. Initially unstructured content remains unverified for dietary/no-cook checks even after edits. Internal reports/overrides are not added to schema.org JSON.

## Implementation and checks

`ConvertTo-RecipeJson` still returns a JSON string by default. `-IncludeClassificationReview` returns an object with Json, Review and Context for the GUI; isolated conversion workers receive the classifier function and configuration explicitly. JSON exports use recipeCategory/keywords and a brief comment note; source scripts load configuration at startup and EXEs embed it at build time. Offline classification remains empty.

Run Test-Classification.ps1 for scoped decisions, missed labels, supporting ingredients, estimates, dietary conflicts, plant alternatives, negation, alternative appliances, citations, overrides and category limits. Test-Core.ps1, Test-RecipeQa.ps1 and Test-SourceQa.ps1 retain source fidelity and classification regression checks. Test-Gui.ps1 checks inline evidence and rechecks. Build/release scripts include the new classification tests. Live-model and packaged import checks do not establish dietary suitability.

See FUTURE-DEVELOPMENTS.md for refinements, a configuration editor and required tools.

## Classification settings (Unreleased)

Open the cog in the top bar and choose Tags or Categories. Edit the name and selection instruction for each entry, or use Add and Remove. Save settings applies the list to the next conversion. Cancel discards the draft. Names must be unique within each list and both lists need at least one entry. Settings persist in `%LOCALAPPDATA%\MealieJsonCreate\classification-settings.json`. Existing recipes keep their selections.

Default tags start with their group's Ollama instruction. Editing one tag gives it its own rule. New, renamed or edited labels use the model's selection under that instruction instead of their original local matching heuristics. Untouched labels continue using built-in evidence checks. Approved names constrain the output schema and the manual review choices. Test-Gui.ps1 exercises editing, saving, reading back and removing entries.

## Individual tag instructions

Each approved tag has one name/description entry in tagDefinitions in Recipe.Classification.json. The description is its default plain-English selection instruction, displayed in settings and included in the Ollama classification request. tagGroups.rules contains shared guidance for that group. For example, Soup describes a finished soup and Curry describes a curry; they no longer display the same generic dish-type sentence. Categories use their existing individual descriptions.

Custom tag instructions are sent in a single-label Custom group, and its edited rule supplies that label's definition. Old saved defaults that exactly match their original group guidance are upgraded in memory. User-edited rules and renamed or deleted labels survive loading. Save settings persists the upgrade. The approved vocabulary itself is unchanged.

Dietary contradiction checks use the recipe as written, including meat stocks and optional animal ingredients. Common configured plant alternatives are normalised for matching. They run on conversion and classification recheck. A deliberate manual checkbox override is preserved; the reason identifies it as manual. Test-Classification.ps1 and Test-RecipeQa.ps1 cover a model returning Vegetarian/Vegan for the chicken curry fixture, and customised dietary rules cannot bypass automatic exclusion.

## Model contradiction review

Conversion reviews selected tags together after local evidence checks when there are multiple tags or uncertainty. One focused request returns keep/remove/review decisions with ingredient/method IDs. An omitted tag is retained with an explicit manual-review reason. Source-backed removals are applied automatically and their reasons appear in the editor. Ambiguous review decisions stay checked. Invalid responses retain the existing recommendations and add a review note. Compatible ingredient tags and the Vegan/Vegetarian pair may coexist. Manual checkbox overrides take precedence on local recheck. Recipe/timing edits clear previous model resolutions; fresh model review requires conversion. Dietary ingredient exclusions remain active independently.
