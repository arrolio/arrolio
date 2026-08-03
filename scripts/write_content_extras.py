#!/usr/bin/env python3
"""Write remaining content/* files."""
import os

P = bytes([0x41, 0x72, 0x72, 0x6f, 0x6c, 0x69, 0x6f]).decode()
PROJ = P

FILES = {}

FILES['lib/arrolio/content/inline_run.rb'] = f'''# frozen_string_literal: true

module {PROJ}
  module Content
    class InlineRun
      attr_reader :text, :style_id, :href

      def initialize(text, style_id: :inline, href: nil)
        @text = text.to_s
        @style_id = style_id.to_sym
        @href = href
        freeze
      end

      def ==(other)
        other.is_a?(self.class) &&
          text == other.text &&
          style_id == other.style_id &&
          href == other.href
      end

      alias eql? ==

      def hash
        [self.class, text, style_id, href].hash
      end
    end
  end
end
'''

FILES['lib/arrolio/content/table.rb'] = f'''# frozen_string_literal: true

module {PROJ}
  module Content
    class Table
      attr_reader :header, :body, :column_widths, :style_id, :id

      def initialize(header: [], body: [], column_widths: nil,
                     style_id: :table, id: nil)
        @header = header.map {{ |row| coerce_row(row) }}.freeze
        @body = body.map {{ |row| coerce_row(row) }}.freeze
        @column_widths = column_widths&.map(&:to_f)&.freeze
        @style_id = style_id.to_sym
        @id = id
        freeze
      end

      def rows
        @header + @body
      end

      def column_count
        rows.map {{ |r| r.cells.length }}.max || 0
      end

      def ==(other)
        other.is_a?(self.class) &&
          header == other.header &&
          body == other.body &&
          column_widths == other.column_widths &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, header, body, column_widths, style_id, id].hash
      end

      private

      def coerce_row(row)
        case row
        when Row then row
        when Array then Row.new(row.map {{ |c| c.is_a?(Cell) ? c : Cell.new(c) }})
        else
          raise ContentError, "Table row must be an Array or Table::Row (got #{{row.class}})"
        end
      end
    end

    class Table::Row
      include Enumerable
      attr_reader :cells

      def initialize(cells)
        @cells = Array(cells).freeze
        freeze
      end

      def each(&block)
        @cells.each(&block)
      end

      def length
        @cells.length
      end

      def ==(other)
        other.is_a?(self.class) && cells == other.cells
      end

      alias eql? ==

      def hash
        [self.class, cells].hash
      end
    end

    class Table::Cell
      attr_reader :content, :colspan, :rowspan, :style_id, :align

      def initialize(content = [], colspan: 1, rowspan: 1,
                     style_id: :table_cell, align: nil)
        @content = Array(content).freeze
        @colspan = colspan.to_i
        @rowspan = rowspan.to_i
        @style_id = style_id.to_sym
        @align = align
        freeze
      end

      def text
        @content.map do |node|
          node.is_a?(Paragraph) ? node.text : node.to_s
        end.join(' ')
      end

      def ==(other)
        other.is_a?(self.class) &&
          content == other.content &&
          colspan == other.colspan &&
          rowspan == other.rowspan &&
          style_id == other.style_id &&
          align == other.align
      end

      alias eql? ==

      def hash
        [self.class, content, colspan, rowspan, style_id, align].hash
      end
    end
  end
end
'''

FILES['lib/arrolio/content/list.rb'] = f'''# frozen_string_literal: true

module {PROJ}
  module Content
    class List
      attr_reader :items, :kind, :style_id, :id

      def initialize(items = [], kind: :bullet, style_id: :list, id: nil)
        @items = items.map {{ |i| i.is_a?(Item) ? i : Item.new(i) }}.freeze
        @kind = kind.to_sym
        @style_id = style_id.to_sym
        @id = id
        freeze
      end

      def ordered?; @kind == :ordered; end
      def bullet?;  @kind == :bullet; end

      def ==(other)
        other.is_a?(self.class) &&
          items == other.items &&
          kind == other.kind &&
          style_id == other.style_id &&
          id == other.id
      end

      alias eql? ==

      def hash
        [self.class, items, kind, style_id, id].hash
      end

      class Item
        attr_reader :content, :marker

        def initialize(content, marker: nil)
          @content = Array(content).freeze
          @marker = marker
          freeze
        end

        def text
          @content.map do |node|
            node.is_a?(Paragraph) ? node.text : node.to_s
          end.join(' ')
        end

        def ==(other)
          other.is_a?(self.class) && content == other.content && marker == other.marker
        end

        alias eql? ==

        def hash
          [self.class, content, marker].hash
        end
      end
    end
  end
end
'''

if __name__ == '__main__':
    os.chdir('/Users/mulgogi/src/arrolio/arrolio')
    for path, content in FILES.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w') as f:
            f.write(content)
        print(f'wrote {path} ({len(content)} bytes)')
