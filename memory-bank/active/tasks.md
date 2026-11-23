# Current Task: Fix the Gemfile.lock release workflow

**Complexity:** Level 1

## Fix

- What broke: on release-please pull requests, `update-gemfile-lock` runs `bundle install` in the Ruby image, then `nick-fields/retry` runs git. Git exits 128 with `fatal: detected dubious ownership in repository at '/__w/jekyll-auto-thumbnails/jekyll-auto-thumbnails'`. `Gemfile.lock` is never pushed.
- Why: `actions/checkout` writes `safe.directory` into a temporary `HOME`. The commit step's git process does not own the workspace directory. The job container runs as root and rewrites `Gemfile.lock` as root, but git stores mode and bytes, not uid, so that ownership is not part of the commit.
- What changed: the retry command runs `git config --global --add safe.directory '*'` before any other git command.
- Files affected: `.github/workflows/update-gemfile-lock.yaml`
- Test: no spec. An assertion on the workflow text would fail only when that text is edited. The failure reproduces only in the Actions container job.

## QA Results

- **Status:** PASS
- **Findings:**
  - Implementation satisfies all requirements, constraints, and acceptance criteria cleanly (`git config --global --add safe.directory '*'` inside the retry step, valid YAML, no `chown` or container user overrides, no extra repo files).
  - **Advisory (non-blocking):** Branch commit `b7653d6` uses `fix(ci):`. Because `release-please` treats `fix` on `main` as release-triggering (per `CONTRIBUTING.md`), prefer `chore(ci):` when titling/squashing the PR unless cutting a gem release for this CI fix is desired.
