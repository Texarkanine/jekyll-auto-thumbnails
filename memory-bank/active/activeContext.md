# Active Context

## Current Task: Write width and height on measured article images
**Phase:** REFLECT COMPLETE

## What Was Done
- Implemented [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70). Measured local images inside `<article>` publish both `width` and `height` for the file the browser loads.
- Preflight passed with an advisory. QA passed. The generator pixel-cache advisory was not built.
- Reflection: `memory-bank/active/reflection/reflection-20261122-issue-70-image-dimensions.md`
- Success criteria now include the published pair. System patterns now say an unreadable thumbnail does not receive the original size.
- Opened draft pull request [#71](https://github.com/Texarkanine/jekyll-auto-thumbnails/pull/71) on `scrolljumpfix`. Title: `fix: write width and height on measured article images`.

## Next Step
- Run `/niko-archive` to archive this task. Do not open another pull request. The draft is #71.
