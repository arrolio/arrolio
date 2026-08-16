# frozen_string_literal: true

module Arrolio
  module Engine
    # Two-pass page-flow driver.
    class Paged
      attr_reader :layout_spec, :flowables, :pages, :context

      def initialize(layout_spec:, flowables:)
        @layout_spec = layout_spec
        @flowables = flowables
        @pages = []
      end

      def layout
        @pages = []
        @page_count_opened = 0
        @footnote_page_map = {}
        @prev_space_after = 0.0
        context = FlowContext.new(layout_spec: @layout_spec, page_number: 1)
        pending = @flowables.dup
        page_state = open_page(context)

        until pending.empty?
          flowable = pending.shift

          if flowable.is_a?(Flowables::PageSequenceStart)
            @current_role = flowable.role
            @current_header = flowable.header_template
            @current_footer = flowable.footer_template
            @current_header_align = flowable.header_align
            @current_footer_align = flowable.footer_align
            unless page_state.fresh && page_state.body_boxes.empty?
              page_state = open_page(context)
            end
            page_state.role = @current_role
            page_state.header = @current_header
            page_state.footer = @current_footer
            page_state.header_align = @current_header_align
            page_state.footer_align = @current_footer_align
            page_state.title_template = flowable.title_template
            @title_template = nil
            @prev_space_after = 0.0
            next
          end

          if flowable.is_a?(Flowables::PageBreak)
            page_state = open_page(context)
            @prev_space_after = 0.0
            next
          end

          if flowable.is_a?(Flowables::FootnoteMarkerFlowable)
            key = flowable.footnote.id || flowable.footnote.marker
            @footnote_page_map[key] ||= page_state.page_number
            page_state.footnotes << flowable.footnote unless page_state.footnotes.include?(flowable.footnote)
            next
          end

          page_state = open_page(context) if flowable.page_break_before? && @pages.any? && !page_state.fresh
          if page_state.frame.full?
            page_state = open_page(context)
            @prev_space_after = 0.0
          end

          width = page_state.frame.width
          if flowable.keep_together? &&
             flowable.height(width, context) > page_state.frame.remaining_height &&
             flowable.height(width, context) <= page_state.frame.height
            page_state = open_page(context)
            @prev_space_after = 0.0
          end

          if flowable.is_a?(Flowables::HeadingFlowable)
            context.record_heading(number: flowable.number,
                                   title: flowable.title,
                                   level: flowable.level,
                                   page_number: page_state.page_number,
                                   id: flowable.id)
          end

          page_state.fresh = false
          page_state = place(page_state, flowable, context, pending)
        end

        @context = context
        context.page_count = @pages.length
        finalize_pages
        @pages
      end

      private

      def place(page_state, flowable, context, pending)
        frame = page_state.frame
        width = frame.width
        natural = flowable.height(width, context)

        if natural <= frame.remaining_height
          emit(page_state, flowable, context)
          @prev_space_after = flowable.space_after.to_f
        elsif flowable.splittable?
          head, tail = flowable.split(width, frame.remaining_height, context)
          if head
            emit(page_state, head, context)
            @prev_space_after = head.space_after.to_f
            pending.unshift(tail) if tail
          else
            return page_state unless frame.full?

            new_state = open_page(context)
            @prev_space_after = 0.0
            place(new_state, flowable, context, pending)
          end
        else
          emit(page_state, flowable, context)
          @prev_space_after = flowable.space_after.to_f
        end
        page_state
      end

      def emit(page_state, flowable, context)
        frame = page_state.frame
        x = frame.x
        y_top = frame.cursor_y

        curr_before = flowable.space_before.to_f
        overlap = [@prev_space_after, curr_before].min
        adjusted_y = y_top + overlap

        boxes, consumed = flowable.emit(x, adjusted_y, frame.width, context)
        page_state.body_boxes.concat(boxes)
        frame.consume!(consumed - overlap)
      end

      def open_page(context)
        template = @layout_spec.page_template
        body = template.body_region
        @page_count_opened = (@page_count_opened || 0) + 1
        page_number = @page_count_opened

        frame = Frame.new(x: body.x, y: body.y,
                          width: body.width, height: body.height)
        context.page_number = page_number

        state = OpenPage.new(
          template: template,
          page_number: page_number,
          frame: frame,
          body_boxes: [],
          fresh: true,
          role: @current_role || :body,
          header: @current_header,
          footer: @current_footer,
          header_align: header_align_for(page_number),
          footer_align: @current_footer_align || :center,
          footnotes: []
        )
        @pages << state
        state
      end

      # Pick header alignment based on page parity. Even pages
      # have left-aligned headers; odd pages have right-aligned
      # headers (matches the XSL-FO convention used by every
      # flavor: insertHeaderEven left, insertHeaderOdd right).
      def header_align_for(page_number)
        explicit = @current_header_align
        return explicit if explicit
        return :left if page_number.even?

        :right
      end

      def finalize_pages
        total = @pages.length
        built = @pages.map do |state|
          template = state.template
          body = template.body_region
          region = Output::Region.new(
            name: :body,
            x: body.x, y: body.y, width: body.width, height: body.height,
            placed_boxes: state.body_boxes
          )
          Output::Page.new(
            number: state.page_number,
            template_name: template.name,
            template_role: state.role,
            page_size: template.page_size,
            regions: { body: region },
            header_text: format_text(state.header, state.page_number, total),
            footer_text: format_text(state.footer, state.page_number, total),
            header_align: state.header_align,
            footer_align: state.footer_align,
            footnotes: state.footnotes,
            title_text: state.title_template
          )
        end
        @pages.replace(built)
      end

      def format_text(template_text, current, _total)
        return nil if template_text.nil?

        template_text.to_s.gsub('%d', current.to_s)
      end
    end

    OpenPage = Struct.new(:template, :page_number, :frame, :body_boxes,
                          :fresh, :role, :header, :footer,
                          :header_align, :footer_align, :footnotes,
                          :title_template,
                          keyword_init: true)
  end
end
