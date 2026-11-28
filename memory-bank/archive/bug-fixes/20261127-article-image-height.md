---
task_id: article-image-height
complexity_level: 1
date: 2026-11-27
status: completed
---

# TASK ARCHIVE: Keep article image ratio when the column shrinks

## SUMMARY

A measured article image still publishes both `width` and `height`. On a page the rewrite already changes, the plugin also prepends `<style>:where(article img){height:auto}</style>` to `head`, so a theme that only sets `max-width: 100%` does not stretch the picture when the column is narrower than the width attribute. An author `height` still wins. Pages with nothing to rewrite stay the same object.

Both cycles were classified Level 1. The first cycle chose the mechanism, built it, and passed QA. A later review reworked the README on the same task, also at Level 1, and passed QA. Pull request [#74](https://github.com/Texarkanine/jekyll-auto-thumbnails/pull/74) is the pull request for this work.

## REQUIREMENTS

- Keep publishing both `width` and `height` for the file the browser loads.
- Those attributes must not lock the used height when the used width is smaller than the width attribute.
- A site stylesheet that sets a height on an image must still win.
- Pages with nothing to rewrite stay the same object, unparsed and unserialized.
- The blog's existing gem config and theme CSS need no change.
- Dropping the height attribute is not a fix. It brings the heading jump back.
- `max_width` stays the file cap at the column ceiling. The theme rule was already shrinking the width.
- The plugin still touches article images only.
- Rework, from review 6094664558: How It Works step 4 says why the style tag is injected. Narrow columns names the `width` and `height` attributes.

## IMPLEMENTATION

`Hooks.replace_urls` still writes the served `width` and `height`, and still returns the input object when nothing changed. When the document did change, `release_article_image_height` prepends one `<style>` whose content is `:where(article img){height:auto}`. It skips the tag when a style node already contains that rule with whitespace removed, and it returns without adding a tag when the document has no `head`. `object-fit` is not set.

The creative phase compared four mechanisms and selected the zero-specificity rule. An inline `height: auto` would fix the blog and override class heights. A normal `article img` rule would beat `img { height: ... }`. Docs-only would leave the blog stretched until the theme changed. `:where()` fixes the blog and loses to any real height selector. The cost is browsers that ignore `:where()`, a policy that drops inline `<style>`, and pages this plugin does not already rewrite. Those keep today's behavior.

Shapes the author still owns: a CSS `height` other than this rule, including a fixed length that can still stretch; `max-width` and `max-height` both binding, where the default `object-fit` is fill; a page we do not rewrite; a policy or later pass that strips `<style>`; a browser that ignores `:where()`; images outside `article`; a deliberate attribute stretch, which now keeps the file's ratio; a `<picture>` or `srcset` whose selected file has a different ratio than the attributes we measured.

How It Works step 4 states the tag and why it is there. Narrow columns names the `width` and `height` attributes, says a `max-width: 100%` theme no longer stretches the picture, and says when the style is absent. `memory-bank/productContext.md` records that on a rewritten page the attributes do not lock the height, and that a site rule that sets a height still wins. `memory-bank/systemPatterns.md` records that the rule is prepended only when the rewrite changes the page.

**Key files:** `lib/jekyll-auto-thumbnails/hooks.rb`, `spec/hooks_spec.rb`, `README.md`, `memory-bank/productContext.md`, `memory-bank/systemPatterns.md`.

## TESTING

- First-cycle build: 278 examples, 0 failures. RuboCop reported no offenses on the rewrite and its spec.
- First-cycle `/niko-qa`: PASS. 278 examples, 0 failures, 100% line coverage. RuboCop clean. `replace_urls` was also run on a full page, a fragment, and a page with no head, under both parsers. Four advisories, none blocking.
- README rework: no new spec. A test of those sentences would fail only when the prose is edited on purpose. Suite rerun: 278 examples, 0 failures, 100% lines.
- Rework `/niko-qa`: PASS. Both review comments are addressed. One advisory, not blocking: step 4 and Narrow columns state the same stretch reason. The brief allowed a pointer to Narrow columns and did not require one.

## LESSONS LEARNED

No reflection file. Level 1 does not run reflect. The creative document and `progress.md` are the record, and both are removed with this archive.

- The width and height attributes reserve the ratio and also act as CSS `width` and `height`. `height: auto` turns off the second job for height. The ratio mapping stays, so a shrunk width still gets the matching height.
- `max_width` is the widest file, not the used width on a phone. The theme was already shrinking the width. The new height attribute is what stopped the height from following.
- Duplicate detection compares the rule with whitespace removed. Stripping spaces on the page and then searching for the spaced rule never matches, so the tag would be added twice.
- Under HTML4, a page with no `<head>` gets the attributes and not the rule, because libxml2 does not create a head. HTML5 creates a head. The README states that the style is absent when the page has no `head`.
- The post-QA trim left step 4 as one line and Narrow columns as one section. The review then asked why, and asked which attributes. The rework answered both in place. The stretch sentence now appears in both places.

## PROCESS IMPROVEMENTS

Level 1 has no archive phase. A creative document in that level lives only under `memory-bank/active/` until someone deletes that directory. This archive exists because the operator asked for a record of the whole branch, creative phase included, after both cycles had already passed QA.

## TECHNICAL IMPROVEMENTS

- A page with no `head` under the HTML4 parser still gets `width` and `height` and not the rule, so the used height stays locked. HTML5 is unaffected. No spec runs the rule under `parser: :html4`.
- The style tag is prepended, so it sits in front of `<meta charset>`. The charset still falls inside the first 1024 bytes. Inserting the tag after a charset meta, when one is present, would keep the usual head order.

## NEXT STEPS

None for this task. Pull request #74 is open.

## CREATIVE / TROUBLESHOOTING

Creative document `creative-article-image-height.md`, inlined above. No troubleshooting logs.
