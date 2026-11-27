# Current Task: article-image-height

**Complexity:** Level 1

## Open questions

- [x] How should the rewrite keep width and height without locking the used height, across the attribute and CSS shapes that actually show up? Explored. Decision: prepend `:where(article img){height:auto}` when the page is already being rewritten. [creative-article-image-height.md](creative/creative-article-image-height.md)

## Build

- [x] What broke: a measured article image gained `width` and `height`, and a theme with `max-width: 100%` and no `height` stretched it when the column was narrower than that width.
- [x] Why: the attributes reserve the ratio and also act as a fixed CSS height.
- [x] What changed: a rewritten page prepends `<style>:where(article img){height:auto}</style>`. Unchanged pages stay the same object. Author `height` rules still win. `object-fit` is not set.
- [x] Files: `lib/jekyll-auto-thumbnails/hooks.rb`, `spec/hooks_spec.rb`, `README.md`, `memory-bank/systemPatterns.md`, `memory-bank/productContext.md`.
