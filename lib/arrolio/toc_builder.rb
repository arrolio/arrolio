# frozen_string_literal: true

module Arrolio
  module TocBuilder
    module_function

    def build_flowables(context, layout_spec, rules: {})
      styles = rules.fetch('styles', {})
      entries = context.heading_entries
      entries.map do |entry|
        number = entry[:number]
        title = entry[:title].to_s
        label = number ? "#{number} #{title}" : title
        style_id = style_id_for(entry[:level], styles)
        style = layout_spec.resolve_style(style_id)
        Flowables::TocLineFlowable.new(
          label,
          entry[:page_number],
          level: entry[:level] || 1,
          style: style
        )
      end
    end

    def style_id_for(level, styles)
      key = level.to_i >= 2 ? 'sub' : 'entry'
      default_style = key == 'sub' ? 'toc_entry_sub' : 'toc_entry'
      (styles[key] || default_style).to_sym
    end
  end
end
