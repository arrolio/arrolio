# frozen_string_literal: true

module Arrolio
  # State threaded through every flowable fit/emit call. Holds
  # page-level state flowables need: current page number, total
  # page count (filled in between pass 1 and pass 2), the running
  # citation table, and the LayoutSpec for style resolution.
  class FlowContext
    attr_accessor :page_number, :page_count, :renderer
    attr_reader :layout_spec, :citations, :heading_entries

    def initialize(layout_spec:, page_number: 1, page_count: nil)
      @layout_spec = layout_spec
      @page_number = page_number
      @page_count = page_count
      @citations = {}
      @heading_entries = []
    end

    def citation_for(ref_id)
      @citations[ref_id.to_s]
    end

    def record_citation(ref_id, page_number)
      @citations[ref_id.to_s] ||= page_number
    end

    def record_heading(number:, title:, level:, page_number:, id: nil)
      @heading_entries << { number: number, title: title, level: level,
                            page_number: page_number, id: id }
    end

    def total_pages
      @page_count
    end
  end
end
