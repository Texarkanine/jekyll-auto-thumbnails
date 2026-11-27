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
