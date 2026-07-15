# Progress

Bump `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0 (gemspec + lockfile) and migrate SimpleCov `add_filter` → `skip` in `spec/spec_helper.rb` in one PR that Fixes #48 and supersedes Dependabot #47.

**Complexity:** Level 2

## 2026-07-15 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Intent restatement approved
    - Classified task as Level 2 Simple Enhancement
* Decisions made
    - Level 2: self-contained dependency + config migration; no creative/architecture phase required
* Insights
    - Issue #48 intentionally folds the Dependabot bump and the deprecation migration into one human PR
