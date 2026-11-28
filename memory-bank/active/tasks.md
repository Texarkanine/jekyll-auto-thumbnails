# Current Task: article-image-height

**Complexity:** Level 1

## Build

- [x] What broke: How It Works step 4 named the injected style and did not say why. Narrow columns opened with "Those attributes" and never named `width` and `height`.
- [x] Why: the post-QA trim left one line on the rule, and the section under it had no referent for its first words.
- [x] What changed: step 4 says the `width` and `height` attributes also set a CSS height, and that `height: auto` keeps a `max-width: 100%` theme from stretching the picture. Narrow columns names those attributes.
- [x] Files: `README.md`. No spec. A test that locks those sentences fails only when the prose is edited on purpose.
- [x] Verify: 278 examples, 0 failures.

## QA

**Result:** PASS

- Rework item 1 met: step 4 now says why the style is added. The `width` and `height` attributes set a CSS height, and `height: auto` stops a `max-width: 100%` theme from stretching the picture.
- Rework item 2 met: Narrow columns opens with "The `width` and `height` attributes".
- Only `README.md` changed outside the memory bank. No code, no spec. The brief and the TDD scope both support that.
- Advisory (DRY, not blocking): the step 4 clause and the second sentence of Narrow columns say nearly the same thing. The brief offered a pointer to Narrow columns as an alternative. It did not require one.
- Suite rerun: 278 examples, 0 failures, 100% lines.
