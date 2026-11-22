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
