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
