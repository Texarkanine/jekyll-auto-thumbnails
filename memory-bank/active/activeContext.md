# Active Context

## Current Task: article-image-height
**Phase:** BUILD - COMPLETE

## What Was Done

- A rewritten page prepends `:where(article img){height:auto}` and still writes both attributes.
- Unchanged pages stay the same object. The rule is not duplicated.
- README lists the shapes the rule does not cover and what the author adds.
- Full suite: 278 examples, 0 failures. RuboCop clean on the rewrite and its spec.

## Next Step

- QA reviews the build against the creative decision.
