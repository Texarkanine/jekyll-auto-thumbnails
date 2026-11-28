# Current Task: article-image-height

**Complexity:** Level 1

## Build

- [x] What broke: How It Works step 4 named the injected style and did not say why. Narrow columns opened with "Those attributes" and never named `width` and `height`.
- [x] Why: the post-QA trim left one line on the rule, and the section under it had no referent for its first words.
- [x] What changed: step 4 says the `width` and `height` attributes also set a CSS height, and that `height: auto` keeps a `max-width: 100%` theme from stretching the picture. Narrow columns names those attributes.
- [x] Files: `README.md`. No spec. A test that locks those sentences fails only when the prose is edited on purpose.
- [x] Verify: 278 examples, 0 failures.
