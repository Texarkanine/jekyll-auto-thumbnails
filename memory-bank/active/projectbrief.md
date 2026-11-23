# Project Brief

## User Story

As a maintainer, I want the release pull request workflow to commit an updated `Gemfile.lock`, so the lockfile on the release branch matches the version in that pull request.

## Use-Case(s)

### Release pull request

Release Please opens a pull request that changes `lib/jekyll-auto-thumbnails/version.rb`. The Release PR workflow runs `bundle install` in the Ruby image from `.ruby-version` and pushes the resulting `Gemfile.lock` onto that branch.

## Requirements

1. The workflow's commit step can run git against the checked-out repository in that job.
2. The pushed `Gemfile.lock` is an ordinary git blob. The job does not persist root ownership into the repository or onto a later checkout.

## Constraints

1. The job stays in the `ruby:` image selected from `.ruby-version`.
2. The commit still retries, because release-please can push to the same branch at the same time.
3. Do not add a `chown` or a non-root container user. Git stores the file mode and the bytes, not the uid. Gems install under `/usr/local/bundle` inside the container. `ubuntu-latest` discards the runner after the job.

## Acceptance Criteria

1. The commit command marks the workspace as a git safe directory in the same process that runs `git commit` and `git push`.
2. The job writes no new repository files besides the `Gemfile.lock` content change Bundler already produces.
