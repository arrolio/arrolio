---
priority: P1
impact: med
depends_on: [50]
layer: architecture
status: done
est: 1d
---

## Problem

A flavor directory was just "three YAML files". There was no
machine-readable manifest declaring the flavor's name, version,
upstream XSL, required fonts, or config-file locations. This meant:

- No way to detect a broken/truncated flavor directory at load time.
- No way to surface flavor metadata in error messages.
- No discovery mechanism for installed flavor gems.

## Approach

1. **`flavors/<name>/manifest.yml`** is the flavor's contract:

   ```yaml
   name: oiml
   version: 1.0.0
   description: OIML International Recommendation
   upstream:
     xsl: oiml.xsl
   doctypes:
     - recommendation
     - document
   fonts:
     required:
       - Times New Roman
       - Jost
     optional:
       - Cambria Math
   config_files:
     layout_spec: layout_spec.yml
     adapter_rules: adapter_rules.yml
     flow_rules: flow_rules.yml
   ```

2. **`Arroolio::Flavor::Manifest`** class (autoloaded from
   `lib/arrolio/flavor/manifest.rb`): loads + validates the manifest,
   provides typed accessors (`name`, `version`, `description`,
   `required_fonts`, `optional_fonts`, `config_path_for(:layout_spec)`).
3. **`ConfigDrivenPipeline.new(flavor_dir:)`** auto-detects the
   manifest if present and exposes it via `pipeline.manifest`.
4. **`Flavor::Manifest.load(flavor_dir)`** raises
   `Arroolio::FlavorError` (new typed error) with structured metadata
   when the manifest is missing or malformed.
5. **Manifests added** to `flavors/oiml/manifest.yml` and
   `spec/fixtures/flavors/sample/manifest.yml`.

## Done-When

- [x] `Arroolio::Flavor::Manifest` class with typed accessors
- [x] `Arroolio::FlavorError` typed error for missing/malformed manifests
- [x] `flavors/oiml/manifest.yml` exists
- [x] `spec/fixtures/flavors/sample/manifest.yml` exists
- [x] `ConfigDrivenPipeline` exposes `pipeline.manifest`
- [x] Specs cover: valid manifest load, missing manifest, malformed
      manifest, missing required field
- [x] All 249+ specs still pass

## Verification

- `bundle exec rspec spec/arrolio/flavor/manifest_spec.rb`
- `bundle exec rake` is green
- OIML r060/1 fixture still renders via the generic pipeline
