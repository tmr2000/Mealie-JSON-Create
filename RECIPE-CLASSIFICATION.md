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

The configuration's `dietaryValidation` rules remove conflicting dietary selections after generation and add a review note. They use ingredient tags and conservative ingredient-term matching, never automatically grant a dietary tag, and may withhold tags for plant alternatives named coconut milk, peanut butter or vegan chicken. These checks do not establish dietary suitability or recognise every compound ingredient; model judgement and review remain necessary.

### Method

Apply only when the recipe actually uses the method. A tool tag is useful for filtering even though the same appliance may also appear under Required tools.

One pot, Air fryer, Slow cooker, Pressure cooker, Barbecue, No cook.

One pot means one cooking vessel; a mixing bowl does not disqualify it. No cook means no heat is required anywhere in the method. Use Traybake from Dish type for food cooked together on a baking tray.

### Planning

Quick (30 minutes or less), Make ahead, Freezer friendly.

Quick requires a known or explicitly estimated total elapsed time of at most 30 minutes, including waits. Make ahead requires source guidance on preparing in advance. Freezer friendly requires explicit source freezing guidance; do not guess storage suitability or invent storage instructions.

## Selection examples

Illustrative only; actual tags depend on the supplied ingredients and method.

| Recipe | Categories | Tags |
|---|---|---|
| Italian tomato pasta, 25 minutes, explicitly vegan | Main courses | Italian; Pasta; Vegetables; Vegetarian; Vegan; Quick (30 minutes or less) |
| Slow-cooker beef stew | Main courses | Stew; Beef; Slow cooker |
| Hummus with a clearly vegan ingredient list | Sauces & condiments | Beans & lentils; Vegetarian; Vegan; No cook |
| Apple crumble served as pudding | Desserts | No tag required if none of the allowed values fits |

## Source evidence gates

The configuration's `sourceValidation` entries gate selected non-main-course categories using source keywords, require affirmative preparation/freezing guidance for Make ahead and Freezer friendly, and cap Quick at 30 minutes of final total time. Unsupported labels are removed with review notes. These conservative patterns can withhold legitimate labels, and incidental words can pass a gate; they are not a complete semantic classifier. No tag or category is added merely because a pattern matches. Main courses remains model-selected without a keyword gate.

The chicken curry regression fixture must not retain Desserts, Cakes & baking, Vegetarian, Vegan, Make ahead, Freezer friendly or Quick. Source steps must retain both LOW/HIGH cooking options and the final spinach timing. `Test-RecipeQa.ps1` checks these cases and positive controls; `-Live` also runs installed local models.

## Implementation

`Recipe.Classification.json` supplies the Ollama prompt, schema enums and response validation. Categories and tags appear in the preview and export as `recipeCategory` and `keywords`. Duplicate selections are removed, casing is normalised and unknown labels cause a validation error. Offline conversion returns empty classification lists. Source runs load configuration at startup; builds embed it for single-file distribution.

See [FUTURE-DEVELOPMENTS.md](FUTURE-DEVELOPMENTS.md) for follow-on work, including a configuration editor and required tools.
