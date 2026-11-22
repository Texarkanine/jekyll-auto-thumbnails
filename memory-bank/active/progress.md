# Progress

Write both `width` and `height` on every local image inside `<article>` that this plugin has measured, matching the file the browser will load, as specified in [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70) and `memory-bank/active/projectbrief.md`.

Rework: cut README text that does not belong, and use an already recorded measurement for the one-sided match check.

**Complexity:** Level 1

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

## 2026-11-22 - PREFLIGHT - COMPLETE (PASS WITH ADVISORY)

* Work completed
    - Executed Level 2 preflight validation on implementation and test plan in `memory-bank/active/tasks.md`
    - Verified strict TDD sequencing across executable units (Units 1-3) and justified test omission for prose/policy unit (Unit 4)
    - Checked conventions, dependency impacts, and contract compatibility across `Scanner`, `Hooks`, and `HtmlParser`
    - Formulated advisory finding on thumbnail artifact encapsulation and metadata caching in `Generator`
    - Wrote validation result `PASS WITH ADVISORY` to `memory-bank/active/.preflight-status`
* Decisions made
    - Preflight passed with advisory: plan is approved as-is for build without blocking modifications
* Insights
    - All 18 planned test behaviors provide comprehensive coverage of edge cases (px suffixes, unsized max limits, identity returns, missing cache paths)

## 2026-11-22 - BUILD - COMPLETE

* Work completed
    - Recorded measured file pixels from `scan_html` without changing thumbnail registration
    - Wrote served `width` and `height` in `replace_urls`, including when `url_map` is empty
    - `process_site` chooses the generated file's pixels when `src` changes, and the measurement otherwise
    - Updated `README.md` and `memory-bank/systemPatterns.md`
    - Full suite: 274 examples, 0 failures. RuboCop: no offenses
* Decisions made
    - A thumbnail whose pixels cannot be read does not receive the original file's size
    - Hooks specs that stub `scan_html` return `{}`, because `process_site` merges that return value
* Insights
    - The preflight advisory to cache thumbnail pixels on the generator was left for a later task. This build identifies the generated file

## 2026-11-22 - QA - COMPLETE (PASS)

* Work completed
    - Semantic review of the build against the plan in `memory-bank/active/tasks.md`: KISS, DRY, YAGNI, completeness, regression, integrity, documentation
    - Re-ran mechanical checks: 274 examples, 0 failures, 100% line coverage; RuboCop 24 files, no offenses
    - Wrote validation status to `memory-bank/active/.qa-validation-status`
* Decisions made
    - PASS: no blocking findings; the unbuilt preflight advisory stays a later task, not a QA failure
* Insights
    - Measurements-out-of-registry and identify-the-generated-file decisions from planning held up under review

## 2026-11-22 - REFLECT - COMPLETE

* Work completed
    - Compared the issue, the plan, and the build
    - Wrote `memory-bank/active/reflection/reflection-20261122-issue-70-image-dimensions.md`
    - Added the published width and height pair to the product success criteria
    - Recorded that an unreadable thumbnail does not receive the original size
* Decisions made
    - techContext needs no change: the tools and commands are the same
* Insights
    - `scan_html` returned the Nokogiri node set, so stubs had to start returning a hash once `process_site` merged that return
    - `generate` still returns only a path. Returning pixels with the path is a later change

## 2026-11-22 - DRAFT PR - OPEN

* Work completed
    - Pushed `scrolljumpfix` and opened draft pull request [#71](https://github.com/Texarkanine/jekyll-auto-thumbnails/pull/71)
* Decisions made
    - The pull request title is the release-please message: `fix: write width and height on measured article images`
    - The pull request stays a draft until the operator marks it ready

## 2026-11-22 - REWORK - INITIATED

* Work completed
    - Operator chose rework of `20261122-issue-70-image-dimensions` over archive
* Decisions made
    - Current complexity of the completed task: Level 2
    - Rework covers two trims from review: README text that does not belong, and the second identify on a one-sided scan
* Insights
    - Operator: if the README text does not belong, cut it. Do not rewrite it into a corrected version.

## 2026-11-22 - REWORK COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Classified the rework from the operator's request
* Decisions made
    - Level 1. The code change is one branch in `Scanner`. The README change is a cut. The approach is already chosen, and a wrong match check stays inside that one method.
    - The earlier cycle on this task was Level 2. That record stays in the first complexity section above.
* Insights
    - The decision tree splits this between a correction and a small enhancement. Scope, risk, and effort put it at Level 1.

## 2026-11-22 - REWORK BUILD - COMPLETE

* Work completed
    - `dimensions_match_original?` uses a pair already recorded for that URL
    - Restored the original README pass-through sentence and removed the two published-tag samples
    - Full suite: 275 examples, 0 failures, 100% line coverage. RuboCop: no offenses
* Decisions made
    - The branch's re-serialization sentence does not belong in the README. The original sentence still matches the code.
    - The published-tag samples do not belong. How It Works step 4 already states the write.
    - A failed first identify still falls through to a second identify. No sentinel for that path.
* Insights
    - The new example failed with 2 identify calls, then passed with 1. The both-attributes "identify once" example was already one call and stayed green.

## 2026-11-22 - REWORK QA - COMPLETE (PASS)

* Work completed
    - Semantic review of the rework against the operator's two trims: KISS, DRY, YAGNI, completeness, regression, integrity, documentation
    - Verified the restored README sentence matches `main` verbatim and both published-tag samples are gone with step 4 intact
    - Re-ran mechanical checks: 275 examples, 0 failures, 100% line coverage; RuboCop 24 files, no offenses
    - Wrote validation status to `memory-bank/active/.qa-validation-status`
* Decisions made
    - PASS: no blocking findings; the failed-first-identify fallthrough with no sentinel stands as decided in build
* Insights
    - The one-sided match check now reads the pair `calculate_dimensions` recorded, so the second identify only happens when the first read failed

