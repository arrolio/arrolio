# frozen_string_literal: true

module Arrolio
  module Content
    class Builder
      attr_reader :metadata, :sections

      def self.build(metadata: {}, **opts, &block)
        builder = new(metadata: metadata, **opts)
        block&.call(builder)
        builder.to_document
      end

      def initialize(metadata: {})
        @metadata = metadata
        @sections = []
      end

      def section(title = nil, number: nil, level: 1, id: nil,
                  style_id: :section_body, title_style_id: nil, &block)
        sb = SectionBuilder.new(title: title, number: number, level: level, id: id,
                                style_id: style_id, title_style_id: title_style_id)
        block&.call(sb)
        @sections << sb.build
        self
      end

      def to_document
        Document.new(metadata: @metadata, sections: @sections)
      end
    end

    class SectionBuilder
      attr_reader :title, :level, :number, :id, :style_id, :title_style_id

      def initialize(title:, number:, level:, id:, style_id:, title_style_id:)
        @title = title
        @number = number
        @level = level
        @id = id
        @style_id = style_id
        @title_style_id = title_style_id
        @children = []
      end

      def paragraph(text = nil, style_id: :body, id: nil, &block)
        runs = block ? ParagraphBuilder.new.runs(&block) : [InlineRun.new(text.to_s, style_id: :inline)]
        @children << Paragraph.new(runs, style_id: style_id, id: id)
        self
      end

      def list(items, kind: :bullet, style_id: :list, id: nil)
        @children << List.new(items, kind: kind, style_id: style_id, id: id)
        self
      end

      def table(header: [], body: [], column_widths: nil, style_id: :table, id: nil)
        @children << Table.new(header: header, body: body,
                               column_widths: column_widths, style_id: style_id, id: id)
        self
      end

      def section(title = nil, **opts, &block)
        opts[:level] ||= @level + 1
        sub = SectionBuilder.new(title: title, number: opts[:number],
                                 level: opts[:level], id: opts[:id],
                                 style_id: opts.fetch(:style_id, @style_id),
                                 title_style_id: opts[:title_style_id])
        block&.call(sub)
        @children << sub.build
        self
      end

      def build
        Section.new(title: @title, level: @level, number: @number, id: @id,
                    children: @children, style_id: @style_id, title_style_id: @title_style_id)
      end
    end

    class ParagraphBuilder
      def initialize
        @runs = []
      end

      def text(str, style_id: :inline)
        @runs << InlineRun.new(str.to_s, style_id: style_id)
      end

      def strong(str)
        @runs << InlineRun.new(str.to_s, style_id: :strong)
      end

      def em(str)
        @runs << InlineRun.new(str.to_s, style_id: :em)
      end

      def link(str, href)
        @runs << InlineRun.new(str.to_s, style_id: :link, href: href)
      end

      def runs
        return @runs unless block_given?
        yield self
        @runs
      end
    end
  end
end
