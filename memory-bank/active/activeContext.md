# Active Context

## Current Task: article-image-height
**Phase:** COMPLEXITY-ANALYSIS - COMPLETE

## What Was Done

- Level 1. One bug in the article-image rewrite.
- The blog's `max_width: 640` matches the column ceiling. The theme's `img { max-width: 100% }` was stable before width and height were written. The height attribute is what locks the used height.
- The fix stays in this gem: keep both attributes, and add a zero-specificity `height: auto` for article images so author CSS can still set height.

## Next Step

- Load the Level 1 build workflow and fix the rewrite.
