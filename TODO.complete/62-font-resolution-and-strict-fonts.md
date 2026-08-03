---
priority: P2
impact: med
depends_on: [50, 61]
layer: render
status: done
est: 1d
---

## Problem

`layout_spec.yml` used absolute user-local paths for fonts
(`/Users/mulgogi/.fontist/fonts/Times.ttf`). This works on the
developer's machine but breaks for any other consumer. The generated
OIML `layout_spec.yml` baked in my home directory.

## Approach

Implemented `Arroolio::Font::Resolver` — a portable font-resolution
abstraction with a fallback chain:

1. **`FontManifest`** (from `layout_spec.yml`'s `font_manifest:` block):
   explicit family → variant path mapping declared by the flavor.
2. **`font_paths`** (legacy explicit paths in `layout_spec.yml`):
   preserved for backward compatibility.
3. **fontist** (optional runtime dependency): if the `fontist` gem is
   available at runtime, families are looked up via fontist's
   manifest. Skipped silently if fontist is not installed.
4. **PDF standard 14 fallback**: Helvetica, Times-Roman, Courier, etc.
   resolve to themselves (built-in PDF fonts).

Strict mode (from TODO 61) raises `RenderError` listing every
unresolved required font. The resolver never hard-fails when fontist
is absent — it just falls through to the next strategy.

`LayoutSpec` now carries a `font_manifest_config` Hash loaded from
`layout_spec.yml`'s `font_manifest:` block, alongside the existing
`header_footer_config` and `cover_logo_config`.

## Done-When

- [x] `Arroolio::Font::Resolver` class exists, autoloaded
- [x] `Arroolio::Font::FontManifest` class exists, autoloaded
- [x] `LayoutSpec#font_manifest_config` accessor exists
- [x] `Loader` reads `font_manifest:` block from YAML
- [x] Resolution chain: manifest → font_paths → fontist → standard 14
- [x] Strict mode raises `RenderError` with `missing_fonts:` metadata
- [x] Specs cover: each resolution strategy, strict mode, standard 14,
      manifest fallback paths, missing files

## Verification

- `spec/arrolio/font/resolver_spec.rb` (16 specs)
- `bundle exec rake` is green (283 specs)
- The resolver does NOT require fontist at install time — it's a
  runtime-optional integration via `Object.const_defined?(:Fontist)`

## Outcome

Flavors can now declare fonts by family name with optional explicit
paths. When a flavor gem is packaged, the `font_manifest:` block can
list family names; at render time the resolver picks whichever path
the local environment provides (manifest, font_paths, or fontist).

Adding a real fontist integration later is a one-line change in
`fontist_lookup` — the abstraction is in place.
