# Current Task: article-image-height

**Complexity:** Level 1

## Open questions

- [x] How should the rewrite keep width and height without locking the used height, across the attribute and CSS shapes that actually show up? Explored. Decision: prepend `:where(article img){height:auto}` when the page is already being rewritten. [creative-article-image-height.md](creative/creative-article-image-height.md)
