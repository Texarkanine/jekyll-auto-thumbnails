# Current Task: Fix the Gemfile.lock release workflow

**Complexity:** Level 1

## Fix

- What broke: on release-please pull requests, `update-gemfile-lock` runs `bundle install` in the Ruby image, then `nick-fields/retry` runs git. Git exits 128 with `fatal: detected dubious ownership in repository at '/__w/jekyll-auto-thumbnails/jekyll-auto-thumbnails'`. `Gemfile.lock` is never pushed.
- Why: `actions/checkout` writes `safe.directory` into a temporary `HOME`. The commit step's git process does not own the workspace directory. The job container runs as root and rewrites `Gemfile.lock` as root, but git stores mode and bytes, not uid, so that ownership is not part of the commit.
- What changed: the retry command runs `git config --global --add safe.directory '*'` before any other git command.
- Files affected: `.github/workflows/update-gemfile-lock.yaml`
- Test: no spec. An assertion on the workflow text would fail only when that text is edited. The failure reproduces only in the Actions container job.
