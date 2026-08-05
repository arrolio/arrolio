# frozen_string_literal: true

require 'arrolio/error'

module Arrolio
  module Content
    class Document
      attr_reader :metadata, :sections, :preface, :bibliography, :cover,
                  :style_id, :footnotes, :title_block

      def self.build(metadata: {}, **opts, &block)
        Builder.build(metadata: metadata, **opts, &block)
      end

      def initialize(metadata: {}, sections: [], preface: [], bibliography: [],
                     cover: nil, style_id: :document, footnotes: [],
                     title_block: nil)
        @metadata = metadata.to_h.freeze
        @sections = validate_sections(Array(sections), field: :sections).freeze
        @preface = validate_sections(Array(preface), field: :preface).freeze
        @bibliography = validate_sections(Array(bibliography), field: :bibliography).freeze
        @cover = cover
        @style_id = style_id.to_sym
        @footnotes = Array(footnotes).freeze
        @title_block = title_block
        freeze
      end

      def title = @metadata[:title] || @metadata['title']
      def docidentifier = @metadata[:docidentifier] || @metadata['docidentifier']
      def edition = @metadata[:edition] || @metadata['edition']

      def ==(other)
        other.is_a?(self.class) &&
          metadata == other.metadata && sections == other.sections &&
          preface == other.preface && bibliography == other.bibliography &&
          cover == other.cover && style_id == other.style_id &&
          footnotes == other.footnotes
      end
      alias eql? ==

      def hash
        [self.class, metadata, sections, preface, bibliography, cover,
         style_id, footnotes].hash
      end

      private

      def validate_sections(array, field:)
        array.each do |item|
          next if item.is_a?(Section)

          raise ::Arrolio::ContentError.new(
            "#{field} must contain only Content::Section instances; got #{item.class}",
            node: item
          )
        end
        array
      end
    end
  end
end
