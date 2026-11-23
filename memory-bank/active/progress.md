# Progress

Make the Release PR workflow able to commit `Gemfile.lock` from inside the Ruby image, without persisting root ownership into the repository.

**Complexity:** Level 1

## 2026-11-23 - COMPLEXITY-ANALYSIS - COMPLETE

* Work completed
    - Traced the failures since the 2.2.1 release pull request to the commit step in `.github/workflows/update-gemfile-lock.yaml`
    - Classified the work as Level 1
* Decisions made
    - The operator approved the fix and required that root ownership not be written back in a form that causes later problems
    - Meet that requirement by leaving the container user alone. The commit stores file contents, not the uid of the working copy
* Insights
    - `actions/checkout` writes `safe.directory` into a temporary `HOME` that later steps do not see
    - The failed run rewrote the working copy (`Using jekyll-auto-thumbnails 2.2.1 (was 2.2.0)`) and still pushed nothing, because git refused the repository before the commit
