---
task_id: 20261122-issue-70-image-dimensions
complexity_level: 2
date: 2026-11-23
status: completed
---

# TASK ARCHIVE: Write width and height on measured article images

## SUMMARY

Measured local images inside `<article>` now publish both `width` and `height` for the file the browser loads, including when no thumbnail is produced. This closes [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70). The first cycle was Level 2. A later review reworked the same task at Level 1: the one-sided match check uses a pair the scan already recorded, and README text that did not belong was cut. QA passed both cycles. Draft pull request [#71](https://github.com/Texarkanine/jekyll-auto-thumbnails/pull/71) is the pull request for this work.

## REQUIREMENTS

- Write both `width` and `height` on a local `<article>` image the scanner has measured.
- Those numbers match the file the browser loads. A rewritten `src` gets the thumbnail's pixels. A measured image whose `src` stays put gets the measured file's pixels.
- Cover one-sided attributes, an unsized image over a max limit, an unsized image within the limit, and a measured image that gets no thumbnail because the calculated size matches the file.
- Posts and other collection documents use the same path as pages (`site.documents` and `site.pages`).
- Images outside `<article>`, and remote images this plugin does not read, stay as the author wrote them.
- Authors may still request a thumbnail with one side, or with no size plus a max limit. The published pair is the aspect ratio of the served file. CSS still sets the width the reader sees.
- Rework: README text that does not belong is cut, with no replacement write-up. A one-sided image uses the pixels the scan already recorded for the match check.

## IMPLEMENTATION

`Scanner.scan_html` records measured file pixels and still registers a thumbnail only when one should be made. `Hooks.process_site` merges those measurements, builds the thumbnail `url_map`, and builds a served-size map: the generated file's pixels when `src` changes, the measurement otherwise. An unreadable thumbnail file gets no width or height from the original file. `Hooks.replace_urls` writes that pair on `article img`. It returns the original string when both the URL map and the size map are empty, when the HTML has no `<img`, or when nothing changed.

`dimensions_match_original?` uses `measurements[url]` when that pair is already recorded. A failed first identify still falls through to a second identify.

How It Works step 4 now states the rewrite. The branch's extra re-serialization sentence was removed and the original pass-through sentence restored. The two published-tag samples added on the branch were removed. Step 4 remains. `memory-bank/productContext.md` records the published pair as a success criterion. `memory-bank/systemPatterns.md` records that measurements stay out of the thumbnail registry, and that the identity-return contract treats an empty size map the same way it treats an empty URL map.

**Key files:** `lib/jekyll-auto-thumbnails/scanner.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`, `spec/scanner_spec.rb`, `spec/hooks_spec.rb`, `README.md`, `memory-bank/productContext.md`, `memory-bank/systemPatterns.md`.

## TESTING

- Build QA: 274 examples, 0 failures, 100% line coverage. RuboCop: 24 files, no offenses. `/niko-qa` PASS. No blocking findings.
- Rework QA: 275 examples, 0 failures, 100% line coverage. RuboCop: 24 files, no offenses. `/niko-qa` PASS. The new width-only example asserted one identify call.
- Preflight on the Level 2 plan: PASS WITH ADVISORY. Caching thumbnail pixels on the generator stayed a later task.

## LESSONS LEARNED

From the reflection, plus the rework that followed it. The reflection file is removed with this archive.

- `scan_html` used to return the node set from `css.each`. Specs that stubbed it returned nil, and `Hash#merge!` raised once `process_site` merged the return. Stubs now return `{}`.
- ImageMagick `>` geometry means the size passed to `generate` can differ from the file that is written. The served pair comes from the file that will be loaded.
- Measurements stay out of the thumbnail registry, so a within-limit image is not resized and filenames stay as they are.
- A width-only scan already knows both pixels. The match check reads that pair. The second identify remains only when the first read failed.
- README text that does not belong gets cut. The original pass-through sentence still described pages the plugin does not change.

## PROCESS IMPROVEMENTS

The reflection recorded nothing notable about the Level 2 process. The review after reflect did: archive waited until that review's two trims were built and QA'd on the same task, instead of opening a second pull request.

## TECHNICAL IMPROVEMENTS

`generate` still returns only a path, so `process_site` identifies a file the generator just wrote. Returning those pixels with the path is a later change. This task did not need it.

## NEXT STEPS

None for this task. Draft pull request #71 is the pull request. The operator marks it ready. Returning pixels from `generate` is a separate change.

## CREATIVE / TROUBLESHOOTING

No creative-phase documents and no troubleshooting logs for this task.
