---
priority: P0
phase: 1
depends_on: []
layer: foundation
est: 1d
status: in_progress
---

## Problem

The Arrolio gem skeleton already exists (gemspec, Gemfile, lib/arrolio.rb,
error.rb, version.rb). This TODO covers the conventions check, autoload
tree, and project structure that everything else depends on.

## Approach

Already in place (verify, don't redo):
- `lib/arrolio.rb` with autoloads for every planned module.
- `lib/arrolio/version.rb` (`0.1.0.alpha1`).
- `lib/arrolio/error.rb` (Error + LayoutError + RenderError +
  ContentError + LayoutSpecError).
- `spec/spec_helper.rb` + `spec/arrolio/version_spec.rb`.
- `Gemfile` with `gem "pdfrb", path: "/Users/mulgogi/src/claricle/pdfrb"`.

Convention decisions to lock in here:
- `# frozen_string_literal: true` on every file.
- Immutable value objects with `freeze` in constructors where data
  crosses a layer boundary.
- `autoload` only — never `require_relative`, never `require` for
  internal code. Autoloads live in the immediate parent namespace's
  file (create the file if it doesn't exist).
- No `send` to private methods, no `instance_variable_set/get`, no
  `respond_to?` for type checks (`is_a?` only).
- No `double()` in specs — real instances or `Struct.new` stand-ins.
- No hand-rolled `to_h`/`from_h` on models.

## Done-When

- [x] `bundle exec rspec` is green on the seed specs.
- [x] `Arrolio::VERSION` returns `"0.1.0.alpha1"`.
- [x] `Arrolio::Error` descends from `StandardError`.
- [x] `lib/arrolio.rb` lists every planned module as an autoload.
- [ ] `.rubocop.yml` exists and `bundle exec rubocop` is green.
- [ ] `bin/console` exists for interactive exploration.
- [ ] CLAUDE.md documents the architecture for future Claude sessions.
