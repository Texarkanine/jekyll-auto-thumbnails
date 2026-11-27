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
