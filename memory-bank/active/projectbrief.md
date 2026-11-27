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
