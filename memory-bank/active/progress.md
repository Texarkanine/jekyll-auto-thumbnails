# Progress

Write both `width` and `height` on every local image inside `<article>` that this plugin has measured, matching the file the browser will load, as specified in [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70) and `memory-bank/active/projectbrief.md`.

**Complexity:** Level 2

## 2026-11-22 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Read issue 70 and confirmed the restatement with the operator
    - Classified the task as Level 2
    - Wrote the project brief, active context, and task stub
* Decisions made
    - Level 2: the bug crosses the scanner and the HTML rewrite, and it does not change the plugin's architecture
* Insights
    - The scanner already measures local article images. The published tag does not receive both numbers, including when no thumbnail is produced

## 2026-11-22 - PLAN - COMPLETE

* Work completed
    - Mapped issue 70 onto `scan_html`, `replace_urls`, and `process_site`
    - Wrote the Level 2 test plan and the ordered implementation plan in `memory-bank/active/tasks.md`
* Decisions made
    - Measurements stay out of the thumbnail registry, so within-limit images are not resized and filenames stay as they are
    - The served size is the generated file's pixels when a thumbnail exists, and the measured file's pixels when it does not
    - If the thumbnail file cannot be measured, do not write the original size onto a rewritten `src`
* Insights
    - `replace_urls` returns immediately when `url_map` is empty, which would skip every dimension-only update
    - ImageMagick geometry uses `>`, so the size passed to `generate` can differ from the file that is written
