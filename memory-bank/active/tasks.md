# Task: Fix HTML5 validity regression in `replace_urls` (issue #29)

* Task ID: issue-29-html5-parser
* Complexity: Level 2
* Type: Simple enhancement + breaking change

Swap the default HTML parser in `Hooks.replace_urls` (and `Scanner.scan_html`
for consistency) from Nokogiri's libxml2-based HTML4 parser to
`Nokogiri::HTML5`, which does not inject a spurious
`<meta http-equiv="Content-Type">` when serializing. Short-circuit pages with
no `<img>` and pages where no `url_map` entry matched, so untouched pages are
not round-tripped at all. Preserve HTML4 behavior behind a new Jekyll config
option `auto_thumbnails.parser: html4|html5` (default `html5`). On JRuby,
which lacks `Nokogiri::HTML5`, raise a clear configuration error when
`parser` is `html5` (including the default).

Ship as a Conventional Commits breaking change (`feat!:` / `BREAKING CHANGE:`)
so Release Please cuts a major version.

## Test Plan (TDD)

### Behaviors to Verify

**`Hooks.replace_urls`**

- **HTML5 default, no replacement**: input HTML with `<article><img
  src="/a.jpg">` and empty `url_map` → returns the exact input string
  (identity), no parse, no `<meta http-equiv>` injection.
- **HTML5 default, no `<img>` at all**: input `"<!DOCTYPE html><html><head>
  <meta charset='utf-8'></head><body><p>hi</p></body></html>"` with a
  non-empty `url_map` → returns the exact input string (identity, short-
  circuited before parsing).
- **HTML5 default, replacement happens**: input with `<article><img
  src="/a.jpg">` and `url_map = { "/a.jpg" => "/a_thumb.jpg" }` → output
  contains `src="/a_thumb.jpg"` and does **not** contain
  `<meta http-equiv="Content-Type"`.
- **HTML5 default, irrelevant `<img>`**: input with `<article><img
  src="/a.jpg">` but `url_map = { "/other.jpg" => "/other_thumb.jpg" }` →
  returns the exact input string (identity - no replacement made).
- **HTML5 default, `<img>` outside article**: input with `<header><img
  src="/logo.jpg"></header>` and `url_map = { "/logo.jpg" => "/logo_thumb.jpg" }`
  → returns the exact input string (no replacement in non-article region).
- **HTML4 opt-in**: same inputs, with configured parser `html4`, reproduces
  legacy behavior (pages with matching replacements are re-serialized through
  libxml2 and include the `<meta http-equiv>`). This documents / locks in
  the opt-out semantics.

**`Scanner.scan_html`**

- **HTML5 parser finds article images**: existing positive/negative cases
  continue to pass with `parser: html5` (no regression from parser swap).
- **HTML4 opt-in**: existing tests pass with `parser: html4` (legacy path).

**`Configuration`**

- **Default**: absent `parser` key → `config.parser == :html5` on CRuby.
- **Explicit `html5`**: `parser: "html5"` → `config.parser == :html5`.
- **Explicit `html4`**: `parser: "html4"` → `config.parser == :html4`.
- **Invalid value**: `parser: "html6"` → raises `ArgumentError` (or gem-
  specific error subclass) with a message listing valid values.
- **JRuby + `html5`**: on JRuby, `parser: "html5"` (or default) → raises with
  a message directing the user to set `parser: html4` explicitly.

### Edge Cases

- Empty `url_map` with and without `<img>` present (both must be identity).
- HTML without a doctype (fragments) — must not crash, returns identity if
  no replacement.
- Multiple `<article>` regions — replacement still works, serialized output
  valid.
- Content already contains `<meta charset="utf-8">` (the canonical repro from
  the issue) — output must not duplicate with `<meta http-equiv>` on HTML5.

### Test Infrastructure

- Framework: RSpec 3.13 (existing), invoked via `bundle exec rspec`.
- Test location: `spec/`, one `_spec.rb` per `lib/jekyll-auto-thumbnails/`
  module (existing convention).
- Conventions: `RSpec.describe TheClass do ... describe ".method" do ...
  context "..." do ... it "..." do ...`. Doubles for Jekyll site/config.
- New test files: none — extend `spec/hooks_spec.rb`, `spec/scanner_spec.rb`,
  `spec/configuration_spec.rb`.

## Implementation Plan

Ordered steps, each roughly one TDD cycle (red → green → refactor).

1. **Configuration: parser attribute with validation + JRuby guard.**
   - Files:
     - `spec/configuration_spec.rb` (add tests first)
     - `lib/jekyll-auto-thumbnails/configuration.rb`
   - Changes:
     - In spec: add `describe "#parser"` block covering default,
       `"html5"`, `"html4"`, invalid value (raises), and JRuby + `html5`
       raises. Use `stub_const("RUBY_ENGINE", "jruby")` for the JRuby case.
     - In `Configuration`: add `attr_reader :parser`. In `initialize`, read
       `config_hash.fetch("parser", "html5")`, validate via a new
       `parse_parser(value)` private method that:
       - Accepts `"html4"` or `"html5"` (case-insensitive, coerced to
         Symbol `:html4` / `:html5`).
       - Raises `ArgumentError` with a clear message for any other value.
       - When `:html5` is chosen and `RUBY_ENGINE == "jruby"`, raises
         `ArgumentError` with message: "auto_thumbnails: parser: html5 is
         not supported on JRuby (Nokogiri::HTML5 is CRuby-only). Set
         auto_thumbnails.parser: html4 to run on JRuby."
     - Export `:parser` via `attr_reader`.

2. **Hooks: `replace_urls` uses configured parser + short-circuits.**
   - Files:
     - `spec/hooks_spec.rb` (tests first)
     - `lib/jekyll-auto-thumbnails/hooks.rb`
   - Changes:
     - In spec: add a new `describe ".replace_urls"` top-level block that
       calls `Hooks.send(:replace_urls, html, url_map, parser: :html5)`
       (the method is `private_class_method` — existing spec uses
       `described_class.send(...)` pattern for other private methods).
       Cover the six behaviors listed above.
     - In `Hooks`: add a top-level `require "nokogiri/html5" unless
       RUBY_ENGINE == "jruby"`.
     - Change `replace_urls(html, url_map)` to
       `replace_urls(html, url_map, parser: :html5)`.
     - Insert short-circuits in order:
       - `return html if url_map.empty?`
       - `return html unless html.include?("<img")`
     - Parse with `parse_html(html, parser)` helper that dispatches to
       `Nokogiri::HTML5.parse(html)` or `Nokogiri::HTML(html)`.
     - Track `modified = false`; set to `true` whenever an `img["src"]`
       is reassigned.
     - Return `modified ? doc.to_html : html` (identity when nothing
       changed).
     - Update `process_site` to pass `config.parser` into `replace_urls`.

3. **Scanner: accept and honor the parser choice (consistency).**
   - Files:
     - `spec/scanner_spec.rb` (tests first, if needed)
     - `lib/jekyll-auto-thumbnails/scanner.rb`
   - Changes:
     - Existing `Scanner.scan_html(html, registry, config, site_source = nil)`
       already receives `config`. Read `config.parser` inside and dispatch
       to `Nokogiri::HTML5.parse(html)` or `Nokogiri::HTML(html)` via the
       same helper pattern used in `Hooks`. Prefer extracting a shared
       parser helper into a small module (e.g. `JekyllAutoThumbnails::
       HtmlParser`) to avoid duplication, OR duplicate inline if that's
       simpler for a two-call-site spread — decision made during
       implementation.
     - Add one positive test confirming scanner still finds `<article>
       <img>` under both `parser: :html5` and `parser: :html4`.
     - Add `require "nokogiri/html5" unless RUBY_ENGINE == "jruby"` if the
       helper isn't shared.

4. **Wire config through in `initialize_system` / `process_site`.**
   - Files: `lib/jekyll-auto-thumbnails/hooks.rb`
   - Changes:
     - `process_site` passes `config.parser` to both `Scanner.scan_html`
       (already receives config; no signature change needed) and to
       `Hooks.replace_urls(doc.output, url_map, parser: config.parser)`.

5. **Documentation updates.**
   - Files: `README.md`
   - Changes:
     - In the YAML config block, add the `parser: html5` line with a
       comment describing valid values and the default.
     - Add a "HTML5 / HTML4 parser" subsection under "Configuration" (or
       a new "Advanced" section) explaining the default, the opt-out, and
       the JRuby constraint. Mention that on HTML5 themes this avoids the
       duplicate `<meta http-equiv="Content-Type">` injection.
     - Do **not** update CHANGELOG.md by hand — Release Please owns it.
       The `feat!:` commit message will drive the changelog entry.

6. **Lint and test.**
   - Files: n/a
   - Changes: `bundle exec rspec` clean, `bundle exec rubocop` clean.
     `.rubocop.yml` already exempts `lib/**/hooks.rb` from several metrics,
     so the added parser dispatch should be fine.

7. **Commit.**
   - A single conventional commit captures the change:
     - Header: `feat(hooks)!: use HTML5 parser by default; expose parser config`
     - Body: describe the injected-meta bug on HTML5 themes, the short-
       circuit, and reference issue #29.
     - Footer: `BREAKING CHANGE: The default HTML parser is now HTML5
       (Nokogiri::HTML5). On HTML5 sites this eliminates a spurious
       <meta http-equiv="Content-Type"> injection. Set
       auto_thumbnails.parser: html4 to restore the previous behavior.
       JRuby users must set parser: html4 explicitly. Closes #29.`
   - Niko workflow phase-save commits (`chore: saving work before <phase>`)
     will also be produced at each phase boundary, which is fine — the
     substantive breaking-change commit is what Release Please keys on.

## Technology Validation

No new dependencies. `Nokogiri::HTML5` is already available through the
existing runtime pin `nokogiri ~> 1.15` (Gemfile.lock shows 1.19.2;
`Nokogiri::HTML5` has shipped with the gem since 1.12 on CRuby).
Requiring `"nokogiri/html5"` at the top of `hooks.rb` and `scanner.rb`
(guarded by `unless RUBY_ENGINE == "jruby"`) is the standard idiom.

No gemspec version bumps are required. No build tool changes.

## Dependencies

- Existing: `nokogiri ~> 1.15`, `jekyll >= 4.0, < 5.0`.
- No new dependencies.

## Challenges & Mitigations

- **JRuby semantics**: `Nokogiri::HTML5` does not exist on JRuby; requiring
  it will raise `LoadError`. **Mitigation**: the top-level `require` is
  guarded by `unless RUBY_ENGINE == "jruby"`, and `Configuration` hard-
  errors when `parser: html5` is selected under JRuby — so JRuby users are
  only ever on the HTML4 code path.
- **Private method testing**: `replace_urls` and `html_document?` are
  `private_class_method`. **Mitigation**: follow the existing convention in
  `spec/hooks_spec.rb`, which uses `described_class.send(:html_document?,
  doc)` to test private class methods.
- **`html.include?("<img")` false positives**: string matches are crude —
  an HTML comment containing `<img ...>` would bypass the short-circuit.
  **Mitigation**: this is a cheap pre-filter; an HTML comment with `<img`
  will simply fall through to the parse path (slower but still correct).
  No behavioral bug; only a micro-optimization miss.
- **Scanner / Hooks parser drift**: if the two modules picked different
  parsers, HTML5-only elements could be scanned but not rewritten (or vice
  versa). **Mitigation**: both read from the same `Configuration#parser`,
  so they always agree.
- **`.rubocop.yml` metrics**: adding dispatch helpers could nudge
  method/cyclomatic complexity. **Mitigation**: `lib/**/hooks.rb` is
  already exempted from the strictest metrics; factor helpers if the
  rubocop run complains.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Preflight
- [x] Build
- [ ] QA

## Build Log

- **Step 1 ✅** — `Configuration#parser`: `VALID_PARSERS = %i[html4 html5]`,
  `attr_reader :parser`, private `parse_parser` that validates string type,
  case-insensitive value, and JRuby hard-error for `:html5`. 9 new spec
  examples, all green.
- **Step 2 ✅** — `Hooks.replace_urls(html, url_map, parser: :html5)`:
  added two short-circuits (`url_map.empty?` and `html.include?("<img")`),
  changed the loop to track `modified` and return the input unchanged when
  no replacement was made. 9 new spec examples, all green. Scenario from
  issue #29 reproduced and verified: HTML5 output contains no
  `<meta http-equiv="Content-Type">`, no-match/no-`<img>` pages are
  returned by object identity.
- **Step 3 ✅** — New `JekyllAutoThumbnails::HtmlParser` module (preflight
  advisory taken): single `parse(html, parser)` dispatch with the
  `require "nokogiri/html5" unless RUBY_ENGINE == "jruby"` guard at the
  top. `Scanner.scan_html` and `Hooks.replace_urls` both delegate.
  1 new scanner spec example covering `parser: :html4`.
- **Step 4 ✅** — `process_site` passes `config.parser` to
  `Hooks.replace_urls`. `Scanner.scan_html` already received `config` and
  now reads `config.parser` internally. Existing hooks specs updated to
  stub `parser: :html5` on the Configuration double.
- **Step 5 ✅** — `README.md` updated: new `parser` line in the YAML
  config block plus an "HTML parser" subsection documenting the default
  flip, the opt-out, and the JRuby constraint. Release Please owns the
  CHANGELOG.
- **Step 6 ✅** — `bundle exec rspec` clean (102 examples, 0 failures,
  90.94% coverage). `bundle exec rubocop` clean (22 files, 0 offenses
  after autocorrecting two minor Style offenses in `parse_parser`).
- **Step 7** — Deferred to QA phase so the breaking-change commit ships
  at the end of the workflow.
