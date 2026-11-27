# Progress

Keep the width and height written for measured article images, and stop those attributes from stretching the picture when the window is narrower than the column ceiling.

**Complexity:** Level 1

## 2026-11-27 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Traced the stretch to the height attribute meeting `img { max-width: 100% }` with no `height`.
    - Classified the fix as a Level 1 bug in the rewrite.
* Decisions made
    - The blog config stays as it is. The gem has to keep the attributes and release the used height.
    - The release is a zero-specificity `height: auto` on article images, so a real author `height` still wins.
* Insights
    - `max_width` is the widest file, not the used width on a phone. The theme already shrinks the width. The gem's new height attribute is what stopped the height from following.

## 2026-11-27 - CREATIVE - COMPLETE

* Work completed
    - Compared a `:where()` rule, an inline style, a normal `article img` rule, and docs-only.
    - Listed the shapes the winner covers and the shapes the author still owns.
* Decisions made
    - Prepend `:where(article img){height:auto}` when the rewrite already changes the page.
    - Do not set `object-fit`. Do not inject the rule on a page we do not already rewrite.
* Insights
    - Inline style fixes the blog and breaks class heights. `:where()` fixes the blog and loses to those heights.
    - Browsers that ignore `:where()`, and pages we do not rewrite, keep today's behavior.

## 2026-11-27 - PLAN - SKIPPED

* Work completed
    - Level 1 has no plan phase. `/niko-plan` routes to build.
* Decisions made
    - The creative decision is the implementation: prepend `:where(article img){height:auto}` only when the page is already rewritten.
* Insights
    - No further design choice is open.

## 2026-11-27 - BUILD - COMPLETE

* Work completed
    - Prepend `:where(article img){height:auto}` only when `replace_urls` already changes the page.
    - Documented the shapes that stay with the author, in the README.
    - 278 examples, 0 failures. RuboCop reported no offenses on the rewrite and its spec.
* Decisions made
    - Duplicate detection compares the rule with whitespace removed, because the needle itself contains a space.
* Insights
    - Stripping spaces on the page and then searching for the spaced rule never matches, so the tag would be added twice.

## 2026-11-27 - QA - COMPLETE (PASS)

* Work completed
    - Reviewed the diff from `a96a342` to HEAD against the brief and the creative decision. Reran the full suite (278 examples, 0 failures, 100% lines) and RuboCop (clean).
    - Ran `replace_urls` on a full page, a fragment, and a page with no head, under both parsers.
* Decisions made
    - PASS. Every requirement and acceptance criterion is met. Four advisories are recorded in `tasks.md`, and none of them blocks.
* Insights
    - Under HTML4, a page with no `<head>` gets the attributes but not the rule. HTML5 always creates a head.
