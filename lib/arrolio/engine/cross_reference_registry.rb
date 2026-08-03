# frozen_string_literal: true

module Arrolio
  module Engine
    # Collects heading → page-number mappings during layout and
    # resolves cross-references for ToC, page citations, and
    # internal links. The engine records entries during pass 1;
    # after layout is complete, the registry provides resolved
    # references for deferred rendering (e.g., ToC page that
    # appears at the front of the document but needs page numbers
    # from the body).
    #
    # This implements the "deferred rendering" pattern: the ToC
    # section is rendered last (from the registry's resolved data)
    # but appears first in the document. The engine's existing
    # FlowContext#heading_entries feeds into this registry.
    class CrossReferenceRegistry
      Entry = Struct.new(:id, :number, :title, :level, :page_number,
                         keyword_init: true)

      attr_reader :entries

      def initialize
        @entries = []
        @by_id = {}
      end

      # Records a heading during layout pass 1.
      def record(id:, number:, title:, level:, page_number:)
        entry = Entry.new(
          id: id, number: number, title: title,
          level: level, page_number: page_number
        )
        @entries << entry
        @by_id[id.to_s] = entry if id
        entry
      end

      # Resolves a cross-reference target to a page number.
      # Returns nil if the target hasn't been recorded.
      def page_number_for(target_id)
        @by_id[target_id.to_s]&.page_number
      end

      # Resolves a cross-reference target to its full entry.
      def entry_for(target_id)
        @by_id[target_id.to_s]
      end

      # All entries, suitable for ToC generation. Entries are
      # in document order (the order they were recorded).
      # Pass +max_level:+ to filter to a maximum heading level
      # (e.g., only levels 1-2 for a compact ToC).
      def toc_entries(max_level: nil)
        return @entries.dup if max_level.nil?

        @entries.select { |e| e.level <= max_level }
      end

      def empty?
        @entries.empty?
      end

      def count
        @entries.length
      end
    end
  end
end
