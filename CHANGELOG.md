# Changelog

All notable changes to the arrolio gem will be documented in this file.

## [Unreleased]

### Added — 2026-08-01 (initial scaffold)

* Project skeleton: gemspec, Gemfile, Rakefile, README.adoc, LICENSE,
  `.rspec`, `.gitignore`.
* `Arrolio::VERSION` (`0.1.0.alpha1`).
* `Arrolio::Error` base + typed subclasses (`LayoutError`,
  `RenderError`, `ContentError`, `LayoutSpecError`).
* Top-level autoload tree declaring the module structure: `Content`,
  `LayoutSpec`, `Engine`, `Output`, `Renderer`, `Style`,
  `FontMetrics`, `TextLayout`, `Flowables`, `Table`, `List`, `SVG`,
  `FieldRun`, `Composer`. Subclass implementations land in follow-up
  commits as code is ported from `Pdfrb::Layout::*`.
