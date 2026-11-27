# Current Task: article-image-height

**Complexity:** Level 1

## Open questions

- [x] How should the rewrite keep width and height without locking the used height, across the attribute and CSS shapes that actually show up? Explored. Decision: prepend `:where(article img){height:auto}` when the page is already being rewritten. [creative-article-image-height.md](creative/creative-article-image-height.md)

## Build

- [x] What broke: a measured article image gained `width` and `height`, and a theme with `max-width: 100%` and no `height` stretched it when the column was narrower than that width.
- [x] Why: the attributes reserve the ratio and also act as a fixed CSS height.
- [x] What changed: a rewritten page prepends `<style>:where(article img){height:auto}</style>`. Unchanged pages stay the same object. Author `height` rules still win. `object-fit` is not set.
- [x] Files: `lib/jekyll-auto-thumbnails/hooks.rb`, `spec/hooks_spec.rb`, `README.md`, `memory-bank/systemPatterns.md`, `memory-bank/productContext.md`.

## QA

**Result:** PASS. 278 examples, 0 failures, 100% line coverage. RuboCop: no offenses.

All five requirements and three acceptance criteria are met, and the build follows the creative decision. Advisories (none block):

- [ ] HTML4 parser on a page with no `<head>` (fragment, or a layout without head): libxml2 does not create a head, so `release_article_image_height` returns early. The attributes are written and the height still locks. HTML5 creates a head, so it is not affected. No spec runs the rule under `parser: :html4`, and the README does not list this case.
- [ ] The style tag goes in front of `<meta charset>`. That is valid HTML because the charset still falls inside the first 1024 bytes. Inserting it after a charset meta, if one is present, would keep the usual head order.
- [ ] `ARTICLE_IMAGE_HEIGHT_RULE` sits between methods. The other modules declare their constants at the top (for example `Configuration::VALID_PARSERS`).
- [ ] In the first new spec, `include(rule)` is redundant because the next line asserts `rules.first == rule`.
