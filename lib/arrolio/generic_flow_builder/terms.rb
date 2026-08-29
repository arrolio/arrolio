# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Terms
      def term_config
        @rules['term'] || {}
      end

      def term_entry_flowable(entry, out)
        if entry.number
          number_style = resolve(:term).with(margin_top: 12.0, margin_bottom: 0.0)
          out << Flowables::TextFlowable.new(
            [InlineRun.new(entry.number, style: number_style)],
            style: number_style
          )
        end
        if entry.preferred
          preferred_style = resolve(:term).with(margin_top: 0.0, margin_bottom: 6.0)
          out << Flowables::TextFlowable.new(
            entry.preferred.inline_runs.map do |run|
              InlineRun.new(run.text, style: resolve(run.style_id),
                                      baseline_shift: run.baseline_shift,
                                      font_size_scale: run.font_size_scale,
                                      href: run.href)
            end,
            style: preferred_style
          )
        end
        # FOP applies space-before BETWEEN sibling blocks (not before
        # the first) — term definitions' second+ paragraphs (the
        # "(For notes...)" line) and the SOURCE line each carry it.
        entry.definition.each_with_index do |item, index|
          append_child(item, out, standalone: false, in_term: true)
          if index.zero?
            widen_first_definition_widows(out)
          else
            apply_sibling_spacing(item, out)
          end
        end
        return unless entry.source

        source_style = resolve(entry.source.style_id)
                            .with(margin_top: term_config.fetch('source_space_before', 2.0).to_f,
                                  margin_bottom: 2.0)
        source_runs = entry.source.inline_runs.map do |run|
          InlineRun.new(run.text, style: resolve(run.style_id),
                                  baseline_shift: run.baseline_shift,
                                  font_size_scale: run.font_size_scale,
                                  href: run.href)
        end
        out << Flowables::TextFlowable.new(source_runs, style: source_style)
      end

      # An entry's head must keep number + preferred + two
      # definition lines together (the reference moves whole entry
      # heads when those don't fit, leaving its characteristic
      # 50-90pt terms-region page-end gaps).
      def widen_first_definition_widows(out)
        widows = term_config.fetch('definition_widows', 1).to_i
        last = out.last
        return unless widows > 1 && last.is_a?(Flowables::TextFlowable)

        out[-1] = Flowables::TextFlowable.new(
          last.runs,
          style: last.style.with(widows: widows),
          measurer: last.measurer
        )
      end

      # Re-emits the last paragraph flowable with the configured
      # between-sibling space (XSL-FO space-before semantics).
      def apply_sibling_spacing(_item, out)
        spacing = term_config.fetch('definition_paragraph_space_before', 0.0).to_f
        return if spacing.zero? || out.empty?

        last = out.last
        return unless last.is_a?(Flowables::TextFlowable)

        out[-1] = Flowables::TextFlowable.new(last.runs,
                                              style: last.style.with(margin_top: spacing),
                                              measurer: last.measurer)
      end
    end
  end
end
