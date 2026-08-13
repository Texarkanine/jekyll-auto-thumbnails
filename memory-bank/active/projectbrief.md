# Project Brief

## User Story

As a site author watching a Jekyll build, I want AutoThumbnails completion logs to include elapsed time so I can see how much of the build those steps consumed.

## Use-Case(s)

### Use-Case 1

A CI build prints `AutoThumbnails: Generated 72 thumbnails in 12s` and `AutoThumbnails: All thumbnails copied in 1s`, so generation vs copy cost is visible in the log.

### Use-Case 2

A long generate step prints `Generated 72 thumbnails in 7 m 2 s` when elapsed time is a minute or more.

## Requirements

1. Append elapsed time to the `Generated N thumbnails` completion line from `Hooks.process_site`.
2. Append elapsed time to the `All thumbnails copied` completion line from `Hooks.copy_thumbnails`.
3. Format under one minute as `in Xs` (integer seconds). Format one minute or more as `in X m Y s`.
4. Do not add elapsed time to the `Copying N thumbnails to _site` start line.

## Constraints

1. No new runtime dependencies.
2. Preserve existing hook behavior, cache semantics, and HTML rewrite contracts.
3. Public interface is the Jekyll hook log output; log-string tests that assert exact messages must be updated.

## Acceptance Criteria

1. `Generated N thumbnails` includes a trailing elapsed-time suffix in the specified format.
2. `All thumbnails copied` includes a trailing elapsed-time suffix in the specified format.
3. Sub-minute times use `in Xs`; times of 60 seconds or more use `in X m Y s`.
4. Existing AutoThumbnails behavior is unchanged aside from those log suffixes.
