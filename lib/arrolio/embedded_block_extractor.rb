# frozen_string_literal: true

module Arrolio
  # Extracts block-level elements (notes, examples) that are nested
  # inside paragraph elements. In standoc presentation XML, notes can
  # appear as children of <p>, not just as direct children of <clause>.
  # Without extraction, these embedded blocks are silently dropped
  # during inline run collection.
  class EmbeddedBlockExtractor
    SECTION_NAMES = ['clause', 'terms', 'definitions', 'annex', 'annex2'].freeze

    def initialize(rules, converter_registry)
      @rules = rules
      @converter_registry = converter_registry
    end

    def extract(elem)
      blocks = []
      block_names = embedded_block_names
      return blocks if block_names.empty?

      elem.each_recursive do |descendant|
        next unless block_names.include?(descendant.name)
        next if inside_section?(descendant, elem)

        mapping_entry = @rules['element_mapping'][descendant.name]
        converter = @converter_registry[mapping_entry['content_type']]
        next unless converter

        result = yield(converter, descendant, mapping_entry)
        blocks.concat(result)
      end
      blocks
    end

    private

    def embedded_block_names
      block_level = @rules['block_level_elements'] || []
      mapping = @rules['element_mapping'] || {}
      block_level.select { |name| mapping.key?(name) }
    end

    def inside_section?(descendant, root)
      ancestor = descendant.parent
      while ancestor && ancestor != root
        return true if SECTION_NAMES.include?(ancestor.name)

        ancestor = ancestor.parent
      end
      false
    end
  end
end
