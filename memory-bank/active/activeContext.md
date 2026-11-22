# Active Context

## Current Task: Write width and height on measured article images
**Phase:** PLAN - COMPLETE

## What Was Done
- Confirmed intent: implement [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70) as written.
- Classified the task as Level 2.
- Planned the fix in three executable steps: `scan_html` returns the measured file's pixels without changing thumbnail registration; `replace_urls` writes a served `width` and `height`; `process_site` uses the generated file's pixels when `src` changes, and the measurement otherwise.
- Kept thumbnail geometry and filenames unchanged. A nil side in names such as `640x` stays.

## Next Step
- Run preflight on the Level 2 plan.
