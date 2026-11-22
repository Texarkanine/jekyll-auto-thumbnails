# Task: Trim the README and the repeated identify

* Task ID: 20261122-issue-70-image-dimensions
* Complexity: Level 1
* Type: bug fix

## Fix

A width-only article image identified the same file twice: once to fill the missing side, then again to decide whether that size matched the file. The first call already records the file's pixels. `dimensions_match_original?` now uses that pair.

README cuts, no replacement text:

- The branch's re-serialization sentence does not belong. The original pass-through sentence still describes pages the plugin does not change, so that sentence is restored.
- The published-tag samples repeated How It Works step 4, and the `max_width`-only sample named a file this config does not write. Both samples are removed. Step 4 stays.

Files: `lib/jekyll-auto-thumbnails/scanner.rb`, `spec/scanner_spec.rb`, `README.md`

## QA - COMPLETE (PASS)

* `dimensions_match_original?` reuses the recorded pair; width-only spec asserts one identify call
* README pass-through sentence restored verbatim from `main`; both published-tag samples removed, step 4 intact
* Mechanical: 275 examples, 0 failures, 100% line coverage; RuboCop 24 files, no offenses
* No blocking findings on KISS, DRY, YAGNI, completeness, regression, integrity, or documentation
