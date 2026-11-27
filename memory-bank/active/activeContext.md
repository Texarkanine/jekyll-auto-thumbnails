# Active Context

## Current Task: article-image-height
**Phase:** BUILD - IN-PROGRESS

## What Was Done

- Surveyed the attribute and CSS shapes that meet the width and height rewrite.
- Chose a zero-specificity `height: auto` on `article img`, injected only when the page is already rewritten.
- Rejected an inline style and a normal `article img` rule because both override heights people set on purpose.
- Wrote down the shapes this does not cover, and what the author adds for each.

## Next Step

- Build that rule in the rewrite. Keep both attributes. Document the exceptions in the README.
