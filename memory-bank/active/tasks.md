# Task: Write width and height on measured article images

* Task ID: 20261122-issue-70-image-dimensions
* Complexity: Level 2
* Type: bug fix

When the scanner has measured a local image inside `<article>`, the published tag gets both `width` and `height` for the file the browser will load. A rewritten `src` gets the thumbnail file's pixels. A measured image with no thumbnail gets the original file's pixels. Images outside `<article>`, and remote images this plugin does not read, stay as they are. Thumbnail registration, geometry, and filenames stay as they are. [Issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70).

## Test Plan (TDD)

### Behaviors to Verify

- [Width-only request]: an article image with only `width`, whose file identifies as a different size, is still registered at the calculated thumbnail size, and `scan_html` returns that URL mapped to the file's own width and height.
- [Height-only request]: the same split. The registry keeps the calculated thumbnail size. The returned map keeps the file's size.
- [Both explicit, different file]: the registry keeps the HTML width and height. The returned map keeps the file's size.
- [Explicit size matches the file]: the image is not registered, and the returned map still has the file's width and height. Covers a tag that already has both, and a tag with only one side whose calculated other side matches the file.
- [Unsized, over the max]: the registry still stores the configured max, including a nil side when only one max is set. The returned map stores the file's width and height.
- [Unsized, within the max]: the image is not registered, and the returned map has the file's width and height.
- [Not measured]: identify failure, a missing file, an external URL, an image outside `<article>`, an unsized image with no max, or a document with no images leaves that URL out of the map. An unsized image with no max still does not call identify.
- [Dimensions only]: `replace_urls` with an empty `url_map` and a size entry writes both attributes on the matching article image, leaves `src` as it was, and returns a new string.
- [Already correct]: the same call, when the article image already has those exact `width` and `height` strings and `src` is not rewritten, returns the input object.
- [Thumbnail pair]: `url_map` and a size entry both hit. The output `src` is the thumbnail URL. `width` and `height` are the size entry, including when they differ from attributes already on the tag. A `300px` attribute becomes the integer string from the size entry.
- [Src only]: `url_map` hits and that URL has no size entry. `src` changes. Existing `width` and `height` attributes stay as they were.
- [Out of reach]: an image outside `<article>` whose `src` is in both maps is left unchanged, and the input object is returned when nothing else changes. An empty `url_map` and an empty size map, or HTML with no `<img`, still returns the input object.
- [Two tags, one file]: two article images with the same `src` both receive the same `width` and `height`.
- [No thumbnail produced]: `process_site` measures an article image, does not register it, and does not generate a thumbnail. The published tag gains the file's width and height, `src` is unchanged, `url_map` has no entry, and the found-image log stays 0.
- [Served thumbnail]: a generated thumbnail identifies as a size different from the registry request and from the original file. The published `src` is the thumbnail. `width` and `height` are the identified thumbnail size.
- [Unread thumbnail]: generation returns a path, identify of that path fails, and a measurement exists. `src` becomes the thumbnail. The attributes are not filled from the original measurement.
- [Failed generation]: `generate` returns nil and a measurement exists. `src` stays. The attributes are the measurement. The existing warning stays.
- [Nothing measured]: a document whose only image is outside `<article>` is assigned its original string object.

### Test Infrastructure

- Framework: RSpec, via `bundle exec rspec`, configured in `.rspec` and `spec/spec_helper.rb`
- Test location: `spec/`
- Conventions: `spec/<name>_spec.rb` mirrors `lib/jekyll-auto-thumbnails/<name>.rb`. Examples are `it` blocks grouped by `context`. Scanner examples stub `File.exist?` and `ImageMagickWrapper.execute_identify` through the local `stub_identify` helper. Hooks examples use doubles for the site, documents, config, and generator.
- New test files: none

## Implementation Plan

### 1. [x] Record file pixels from the scan — executable

- Files: `spec/scanner_spec.rb`, `lib/jekyll-auto-thumbnails/scanner.rb`

1. Stub tests: add empty examples in `spec/scanner_spec.rb` under `.scan_html` for the seven scanner behaviors above. Do not change existing registration assertions.
2. Stub interface: `Scanner.scan_html` returns a Hash. `calculate_dimensions`, `dimensions_match_original?`, and `check_and_register_oversized` take an optional `measurements:` keyword (default `nil`) and do not use it yet. Existing positional calls stay valid.
3. Write tests and run red: assert the returned `{ url => { width:, height: } }` shape and the registry results in the behavior list. Run those examples and see them fail.
4. Write code and run green: when an existing identify succeeds, store the file's width and height in the hash passed from `scan_html`. Store that pair even when the image is not registered. Do not add an identify call. The existing "invokes identify once" example must stay green. Do not change what `register` receives, including a nil side from `check_and_register_oversized`. Return `{}` when nothing was measured.

### 2. Write the served pair onto the article image — executable

- Files: `spec/hooks_spec.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`

1. Stub tests: add empty examples in `spec/hooks_spec.rb` under `.replace_urls` for the six replace behaviors above.
2. Stub interface: `Hooks.replace_urls(html, url_map, parser: :html5, sizes: {})`. Default `sizes` is an empty hash. The method does not read `sizes` yet. Update the method's comment to name the argument, without describing the new write.
3. Write tests and run red: assert attribute values, unchanged `src` where required, and object identity where required. Run those examples and see them fail.
4. Write code and run green: return the input object when `url_map` and `sizes` are both empty, or when the HTML has no `<img>`, or when no article image actually changes. For an article image whose `src` is in `sizes` with both integers, set `width` and `height` to those integer strings. Set `src` from `url_map` when present. Assign an attribute only when the new string differs. Leave images outside `article img` alone. A URL in `url_map` with no size entry changes `src` only.

### 3. Choose the file the browser will load — executable

- Files: `spec/hooks_spec.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`

1. Stub tests: add empty examples in `spec/hooks_spec.rb` under `.process_site` for the five process behaviors above. In the existing `process_site` `before` hook, stub `Scanner.image_dimensions` to return nil so a missing cache file does not spawn ImageMagick. New examples override that stub.
2. Stub interface: no new method. `process_site` still calls `replace_urls` with the current arguments.
3. Write tests and run red: assert the published attributes, `src`, `url_map`, the found-image count, and object identity in the behavior list. Run those examples and see them fail. Then run the existing `.process_site` examples and keep them green, adjusting only the new `image_dimensions` stub if one of them needs the real method.
4. Write code and run green: merge each `scan_html` return into one measurement hash. When `generate` returns a path, put the URL in `url_map` as today and set the served size from `Scanner.image_dimensions` on that path. Do not fill that URL from the measurement when identify returns nil. When `generate` returns nil, keep the warning and leave the URL out of `url_map`. For a measured URL that was not generated, the served size is the measurement. Pass the served hash as `sizes:` to `replace_urls`. Do not store it on `site.data`. Do not change the found-image log, which still counts `registry.entries`.

### 4. Document the published pair — prose/policy

- Files: `README.md`, `memory-bank/systemPatterns.md`
- No tests: prose/policy artifact

1. In `README.md`, extend "How It Works" so the rewrite writes `width` and `height` for the file the browser loads, including when `src` does not change. Adjust the sentence about byte-for-byte pass-through so a measured article image is a reason to serialize, and an unmeasured page still passes through. In the usage examples, show both attributes on the published tag. Leave thumbnail filenames and the generator geometry alone.
2. In `memory-bank/systemPatterns.md`, update the `replace_urls` description and the `url_map.empty?` short-circuit. The short-circuit applies when there is nothing to rewrite: no thumbnail URL and no served size. State that a served size is the thumbnail file's pixels when `src` changes, and the measured file's pixels when it does not. State that measurements are not thumbnail registrations.

## Technology Validation

No new technology - validation not required

## Dependencies

- ImageMagick, already required, via `Scanner.image_dimensions` and `ImageMagickWrapper.execute_identify`
- Nokogiri, already required, via `HtmlParser` and `replace_urls`
- RSpec, already required

## Challenges & Mitigations

- Writing the registry request, or the original file's size, onto a tag whose `src` is a thumbnail: `process_site` identifies the generated file. The served-thumbnail example uses three different sizes. If identify fails, that URL is not filled from the measurement.
- `replace_urls` returns before any edit when `url_map` is empty, so a dimension-only page would never change: the early return requires both maps to be empty. The dimensions-only example covers it.
- A new identify inside `scan_html` fails the existing "invokes identify once" example: record pixels inside the helpers that already identify. Do not call `image_dimensions` again from `scan_html`.
- Storing measurements in the thumbnail registry would resize within-limit images and change filenames such as `640x`: measurements are the `scan_html` return value. `register` arguments stay as they are.
- `process_site` examples would spawn ImageMagick on missing cache paths: the shared `before` hook stubs `Scanner.image_dimensions` to nil, and the examples that need pixels override it.
- Setting `width` and `height` to the strings already on the tag would drop the identity return and re-serialize the page: assign an attribute only when the string changes. The already-correct example covers it.
- An attribute such as `100%` is already parsed as an integer by `parse_dimension`. Writing the served pixel pair replaces that text. Do not add a case that preserves non-integer attribute text.

## Pre-Mortem

- The plan treats a layout box as a thumbnail requirement, so images that already fit get resized: already covered by the challenge about keeping measurements out of the registry. Step 1 and step 3 keep `register` and the found-image count on the thumbnail set.
- The plan refuses to write pixels because `width` and `height` might lock the CSS used size: write the served pair on every measured article image. Do not add a CSS or percentage exception. The issue's rule is the aspect-ratio hint, and the author's one-sided request stays the thumbnail API.
- The plan stamps the size it asked ImageMagick for: already covered by the served-thumbnail challenge. The `>` geometry can emit a different file, and the test sizes are chosen so a request-sized write fails.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [ ] Build
- [ ] QA
