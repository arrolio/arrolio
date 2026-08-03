# frozen_string_literal: true

module Arrolio
  # Base class for every Arrolio failure mode. Subclasses carry
  # typed metadata that callers can inspect (e.g. +page_number+ on
  # a +LayoutError+, +oid+ on a +RenderError+).
  class Error < StandardError; end

  # Raised by Engine::* when a layout pass fails (overflow that
  # can't be resolved, broken cross-reference, missing template).
  class LayoutError < Error
    attr_reader :page_number, :template_name

    def initialize(message, page_number: nil, template_name: nil)
      @page_number = page_number
      @template_name = template_name
      super(message)
    end
  end

  # Raised by Renderer::* when the render pass fails.
  class RenderError < Error
    attr_reader :missing_fonts

    def initialize(message, missing_fonts: nil)
      @missing_fonts = missing_fonts
      super(message)
    end
  end

  # Raised when the content tree violates Arrolio's content
  # contract (e.g. a Section with a non-String title, or a
  # Paragraph with malformed InlineRuns).
  class ContentError < Error
    attr_reader :node

    def initialize(message, node: nil)
      @node = node
      super(message)
    end
  end

  # Raised when a LayoutSpec is missing required entries or has
  # invalid values (unknown page-template name, unresolvable style
  # reference, etc.).
  class LayoutSpecError < Error
    attr_reader :spec_field

    def initialize(message, spec_field: nil)
      @spec_field = spec_field
      super(message)
    end
  end

  # Raised when a flavor is missing required files (manifest.yml,
  # layout_spec.yml, etc.) or has malformed configuration. Carries
  # the flavor directory and/or manifest path for diagnosis.
  class FlavorError < Error
    attr_reader :flavor_dir, :manifest_path, :missing_fields, :missing_role

    def initialize(message, flavor_dir: nil, manifest_path: nil,
                   missing_fields: nil, missing_role: nil)
      @flavor_dir = flavor_dir
      @manifest_path = manifest_path
      @missing_fields = missing_fields
      @missing_role = missing_role
      super(message)
    end
  end
end
