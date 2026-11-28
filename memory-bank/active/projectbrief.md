# Project Brief

## User Story

As a site author who set `max_width` to the column's ceiling, and whose theme already shrinks images with `max-width: 100%`, I want measured article images to keep both width and height so headings stay put, and I want those images to keep their shape when the window is narrower than that ceiling.

## Use-Case(s)

### Use-Case 1

The blog column is `max-width: 640px`. The gem config is `max_width: 640`. A plain Markdown image is wider than that, so the gem writes a thumbnail and both pixel dimensions. On a narrow window the theme shrinks the width. The picture must stay in ratio.

### Use-Case 2

A Markdown image is marked with a width only (`=640x`). The gem fills in the served height. The same narrow window must not stretch the picture. The heading must still stay put when the image loads.

## Requirements

1. Keep publishing both width and height for the file the browser loads.
2. Those attributes must not lock the used height when the used width is smaller than the width attribute.
3. A site stylesheet that sets a height on an image must still win.
4. Pages with nothing to rewrite stay the same object, unparsed and unserialized.
5. The blog's existing gem config and theme CSS need no change.

## Constraints

1. Dropping the height attribute brings back the heading jump. That is not a fix.
2. The blog config is not wrong. `max_width` is the file cap at the column ceiling. The theme rule was stable before the attributes existed.
3. The plugin still touches article images only.

## Acceptance Criteria

1. When a rewrite writes width and height, the document also carries a zero-specificity rule that sets `height: auto` on article images.
2. An author rule that sets `height` still overrides that rule.
3. Existing served-size behavior, and the unchanged-input identity return, still hold.

## Rework

PR 74 review 6094664558, both comments on `README.md`. The requirements above still hold. This rework changes that README prose only.

1. How It Works step 4 names `<style>:where(article img){height:auto}</style>` and does not say why. Say why there, in one clause: the `width` and `height` attributes also set a CSS height, and `height: auto` keeps a theme with `max-width: 100%` from stretching the picture. A pointer to Narrow columns is enough if the clause would repeat that section.
2. Narrow columns opens with "Those attributes" and never names them. Name the `width` and `height` attributes.
