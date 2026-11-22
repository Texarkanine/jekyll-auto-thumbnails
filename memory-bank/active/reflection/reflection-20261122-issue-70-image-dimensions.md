---
task_id: 20261122-issue-70-image-dimensions
date: 2026-11-22
complexity_level: 2
---

# Reflection: Write width and height on measured article images

## Summary

Measured local images inside `<article>` now publish both `width` and `height` for the file the browser loads. The build matches [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70), and QA passed.

## Requirements vs Outcome

The four gaps in the issue are covered: one-sided attributes, an unsized image over the max, an unsized image within the max, and a measured image that gets no thumbnail. A rewritten `src` gets the thumbnail file's pixels. A measured image with no thumbnail gets the original file's pixels. Images outside `<article>` and remote images are unchanged. Thumbnail registration, geometry, and filenames were left as they were. No requirement was dropped. The only addition was making stubbed `scan_html` calls return `{}` so `process_site` could merge them.

## Plan Accuracy

The three executable steps ran in order and the predicted challenges did not appear at runtime, because the tests asserted them first. The surprise was the old return value of `scan_html`: it returned the Nokogiri node set from `each`, and specs that stubbed the method returned nil. `Hash#merge!` then raised. The `image_dimensions` stub did not disturb the existing process-site examples.

## Build & QA Observations

The scanner and rewrite steps went through red then green without a design change. QA re-ran the suite (274 examples, 0 failures) and RuboCop, and reported no blocking findings. The preflight note about caching pixels on the generator stayed unbuilt, on purpose.

## Insights

### Technical

- `scan_html` used to return the node set from `css.each`, not nil. A new return value has to replace that, and every stub of the method has to return a hash once the caller merges it.
- ImageMagick's `>` geometry means the size passed to `generate` can differ from the file. The served pair has to come from the file that will be loaded.

### Process

- Nothing notable

### Million-Dollar Question

The split we built is the right one: measurements are not thumbnail registrations, and the hook writes the served pair. The leftover is that `generate` still returns only a path, so the hook identifies a file the generator just wrote. If the served pair had been a foundational assumption, `generate` would return those pixels with the path. That cache is a separate change, and this task did not need it.
