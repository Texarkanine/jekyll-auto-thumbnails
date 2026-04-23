# Project Brief: Fix HTML5 validity regression in `replace_urls` (issue #29)

## User Story

As a Jekyll site author using an HTML5 theme (e.g. `no-style-please` or the
Jekyll default), I want `jekyll-auto-thumbnails` to leave my HTML valid after
it runs. Today, Nokogiri's HTML4 parser injects a duplicate
`<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">` alongside
my existing `<meta charset="utf-8">` on every page the plugin touches, which
breaks HTML5 validity (Validator.nu flags it). I also want the plugin to stop
round-tripping pages that have nothing to do with thumbnails.

## Source

GitHub issue: https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/29

## Requirements

### Functional

1. **HTML5 by default**: HTML parsing and serialization in `Hooks.replace_urls`
   use `Nokogiri::HTML5` by default. No injected `<meta http-equiv>` on HTML5
   pages.
2. **Idempotence on no-op pages**: `replace_urls` must return the input `html`
   unchanged (identity) when no `<article><img>` matches `url_map`. Do not
   re-serialize pages where nothing changed.
3. **Short-circuit before parsing**: if the document contains no `<img` at
   all, skip parsing entirely and return the input unchanged.
4. **Opt-out via config**: new Jekyll config option
   `auto_thumbnails.parser: html4|html5` (default `html5`). `html4` restores
   the pre-existing `Nokogiri::HTML` behavior for users who relied on it.
5. **JRuby guardrail**: `Nokogiri::HTML5` is not available on JRuby. When
   running on JRuby with `parser: html5` (including the default), hard-error
   with a clear, actionable message. Correctness > convenience.

### Non-Functional

6. **Breaking change discipline**: commit the default flip as a Conventional
   Commits breaking change (`feat!:` or `BREAKING CHANGE:` footer) so Release
   Please cuts a major version bump.
7. **Documentation**: README and CHANGELOG must describe the new default,
   the opt-out, and the JRuby constraint.
8. **Tests**: Specs cover (a) HTML5 default produces no duplicate
   `<meta http-equiv>`, (b) no-op short-circuit returns input identity,
   (c) `<img`-less short-circuit returns input identity, (d) `parser: html4`
   restores legacy behavior, (e) JRuby + `html5` hard-errors, (f) invalid
   `parser` values are rejected or defaulted.

## Out of Scope

- Changing how images are selected (still `<article> img`).
- Changing how thumbnails are generated or cached.
- Redesigning the hook registration pattern.
- Supporting Jekyll 5 (tracked separately if ever).

## Open Questions (for Plan phase)

- **Scanner parser parity**: `Scanner.scan_html` also uses `Nokogiri::HTML`.
  Should the `parser` config apply there too, for consistency on HTML5 input?
  (Leaning yes — a single setting that governs both read and rewrite paths —
  but to be confirmed in the plan.)
- **Config key naming**: confirmed as `parser` with values `html4` / `html5`.
- **Invalid value handling**: raise, warn-and-default, or silently default?
