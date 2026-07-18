# Active Context

## Current Task: mutation-testing
**Phase:** BUILD - COMPLETE

## What Was Done
- Wired Mutant + mutant-rspec (`config/mutant.yml`, `AGENTS.md`, CONTRIBUTING)
- Drove mutation coverage to **100%** (2338 kills / 0 alive)
- Key structural fixes: HtmlParser `def self.parse` (not `module_function`); stop stubbing SUT (`shell_generate`, `image_dimensions`); make Hooks/Scanner helpers publicly testable; simplify redundant guards/logs
- Verification: `bundle exec rspec` (237), `rubocop` clean, `mutant test`, `mutant run` 100%

## Files created or modified
- New: `AGENTS.md`, `config/mutant.yml`, `spec/support/mutant_setup.rb`, `spec/html_parser_spec.rb`
- Lib: configuration, digest_calculator, generator, hooks, html_parser, imagemagick_wrapper, registry, scanner, url_resolver
- Specs: expanded across modules; SimpleCov gated under Mutant; `/.mutant/` gitignored

## Deviations from Plan
- Made previously-private Hooks/Scanner helpers public so Mutant subjects are observable without `.send` (AGENTS compliance)
- Removed Scanner debug logging (Bucket A — unobserved)
- Line coverage ~99% (286/289); plan allowed not newly enforcing 100% line gate

## Next Step
- Draft PR, then `/niko-qa`
