# frozen_string_literal: true

require File.expand_path('lib/arrolio/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'arrolio'
  spec.version = Arrolio::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'FOP-like paged layout engine for Ruby — renders to PDF via Pdfrb'
  spec.description = <<~HEREDOC
    Arrolio is a paged-media layout engine: it takes a content tree
    plus a layout spec (page templates, styles, flows) and produces a
    sequence of laid-out pages, which a renderer then emits — by
    default to PDF bytes via the sibling `pdfrb` gem.

    Arrolio is the middle layer of a three-library stack:

      * `pdfrb`     — pure-Ruby PDF library (bytes <-> model).
      * `arrolio`  — FOP-like paged layout (this gem; depends on pdfrb).
      * `loom`      — multi-target layout compiler (separate gem; emits
                      to Arrolio, CSS, XSL-FO, IDML).

    Arrolio itself owns: page templates, threaded flows, Knuth-Plass
    line and page breaking, tables, lists, SVG, page-model selection,
    running headers/footers, and the rendering pipeline. It does not
    own the PDF byte format (Pdfrb does) or any DSL (Loom does).
  HEREDOC

  spec.homepage = 'https://github.com/arrolio/arrolio'
  spec.license = 'BSD-2-Clause'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/arrolio/arrolio'
  spec.metadata['changelog_uri'] = 'https://github.com/arrolio/arrolio/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/arrolio/arrolio/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) ||
        f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) ||
        f.start_with?('flavors/')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fontisan', '>= 0.4.45', '< 1.0'
  spec.add_dependency 'fontist', '~> 1.0'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'pdfrb', '~> 0.3.0'
  spec.add_dependency 'rexml'
end
