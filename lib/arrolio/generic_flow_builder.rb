# frozen_string_literal: true

require 'tmpdir'
require 'yaml'

module Arrolio
  class GenericFlowBuilder
    INLINE_SVG_PREFIX = 'inline-svg:'

    attr_reader :layout_spec, :rules, :asset_resolver

    def initialize(layout_spec:, rules:, asset_resolver: nil)
      @layout_spec = layout_spec
      @rules = rules.is_a?(String) ? YAML.safe_load_file(rules, aliases: true) : rules
      @asset_resolver = asset_resolver || AssetResolver.new(base_dirs: [])
    end

    def build(document)
      @document = document
      flowables = []
      page_sequences.each do |sequence|
        source = content_for(document, sequence['role'])
        next if sequence['role'].to_s != 'cover' && sequence['role'].to_s != 'back_of_cover' && source.empty?

        flowables << sequence_start(document, sequence)
        build_sequence_content(document, source, sequence, flowables)
        flowables << Flowables::PageBreak.new if sequence['page_break_after']
      end
      append_inline_footnote_markers(document, flowables)
      append_endnotes(document, flowables)
      flowables
    end

    # Emits a FootnoteMarkerFlowable for each Document#footnote when the
    # flavor opts in via `flow_rules.page_bottom_footnotes: true`. The
    # engine collects these onto the page where they appear (the last
    # body page by default) and the renderer draws them at the bottom.
    #
    # This is a pragmatic bridge until the adapter can emit markers
    # inline at `<fn>` reference sites (TODO 60). Opt-in keeps it
    # disabled by default so existing flavors are unaffected.
    def append_inline_footnote_markers(document, flowables)
      return if document.footnotes.empty?
      return unless @rules['page_bottom_footnotes']

      document.footnotes.each do |footnote|
        flowables << Flowables::FootnoteMarkerFlowable.new(footnote)
      end
    end

    def append_endnotes(document, flowables)
      return if document.footnotes.empty?
      return unless @rules['endnotes']

      flowables << Flowables::PageSequenceStart.new(
        role: :endnotes,
        header_template: nil,
        footer_template: nil
      )
      document.footnotes.each do |footnote|
        marker_text = footnote.marker.to_s
        body = footnote.body.map { |paragraph| paragraph_flowable(paragraph) }
        flowables << Flowables::NoteFlowable.new(
          marker_text,
          body,
          style: resolve(footnote.style_id),
          marker_width: 22.0
        )
      end
    end

    private

    def page_sequences
      Array(@rules['page_sequences'])
    end

    def sequence_start(document, sequence)
      title = sequence['role'].to_s == 'body' ? title_text(document) : nil
      Flowables::PageSequenceStart.new(
        role: sequence.fetch('role'),
        header_template: interpolate(sequence['header'], document),
        footer_template: sequence['footer'],
        header_align: sequence['header_align'] || :right,
        footer_align: sequence['footer_align'] || :center,
        initial_page_number: sequence['initial_page_number'],
        title_template: title
      )
    end

    def build_sequence_content(document, source, sequence, out)
      if sequence['build_content'] == 'cover_content'
        build_cover_content(document, out)
      elsif source.is_a?(Array)
        build_sections(source, out)
      end
    end

    def title_text(document)
      return nil unless document.title_block

      text = document.title_block.inline_runs.map(&:text).join.strip
      text.empty? ? nil : text
    end

    def content_for(document, role)
      case role.to_s
      when 'preface' then document.preface
      when 'body' then document.sections
      when 'bibliography' then document.bibliography
      else []
      end
    end

    def build_cover_content(document, out)
      Array(@rules['cover_content']).each do |entry|
        next unless condition_matches?(entry['when'], document)

        case entry['type'].to_s
        when 'spacer'
          out << Flowables::Spacer.new(entry.fetch('size').to_f)
        when 'text'
          style = resolve(entry.fetch('style'))
          style = style.with(align: :center) if entry.fetch('align', 'center').to_sym == :center
          text = interpolate(entry.fetch('source'), document)
          out << Flowables::TextFlowable.new([InlineRun.new(text, style: style)], style: style)
        end
      end
    end

    def build_sections(sections, out)
      section_rules = @rules.fetch('section', {})
      break_between = section_rules.fetch('insert_page_break_before', false)
      sections.each_with_index do |section, index|
        needs_break = break_between && index.positive? && !bibliography_section?(section)
        out << Flowables::PageBreak.new if needs_break
        build_section(section, out)
      end
    end

    def bibliography_section?(section)
      section.children.any?(Content::BibliographyItem)
    end

    def build_section(section, out)
      if section.heading?
        out << Flowables::HeadingFlowable.new(
          section.title.to_s,
          level: section.level,
          number: section.number,
          id: section.id,
          style: resolve(section.title_style_id)
        )
      end

      children = section.children
      children = prefix_number(section.number, children) if !section.heading? && section.number
      children.each { |child| append_child(child, out) }
    end

    def prefix_number(number, children)
      return children if children.empty? || !children.first.is_a?(Content::Paragraph)

      first = children.first
      prefix = Content::InlineRun.new("#{number}  ", style_id: :caption_label)
      updated = Content::Paragraph.new(
        [prefix] + first.inline_runs,
        style_id: first.style_id,
        id: first.id,
        footnote_refs: first.footnote_refs
      )
      [updated] + children.drop(1)
    end

    def emit_footnote_markers_for(paragraph, out)
      return if paragraph.footnote_refs.empty?
      return unless @document

      paragraph.footnote_refs.each do |ref_id|
        footnote = @document.footnotes.find { |fn| fn.id == ref_id || fn.marker == ref_id }
        next unless footnote

        out << Flowables::FootnoteMarkerFlowable.new(footnote)
      end
    end

    def append_child(child, out, standalone: true)
      case child
      when Content::Paragraph
        out << paragraph_flowable(child, standalone: standalone)
        emit_footnote_markers_for(child, out)
      when Content::Note
        out << note_flowable(child)
      when Content::Example
        out << example_flowable(child)
      when Content::FigureGroup
        figure_group_flowable(child, out)
      when Content::TermEntry
        term_entry_flowable(child, out)
      when Content::BibliographyItem
        bibliography_item_flowable(child, out)
      when Content::Section
        build_section(child, out)
      when Content::Table
        caption = table_caption_for(child)
        out << Flowables::TableFlowable.new(child,
                                            style: resolve(child.style_id),
                                            caption_text: caption,
                                            caption_style: resolve(:figure_caption).with(align: :left),
                                            **table_geometry)
      when Content::List
        out << list_flowable(child)
      when Content::Image
        out << image_flowable(child)
      when Content::Preformatted
        out << preformatted_flowable(child)
      when Content::PageBreak
        out << Flowables::PageBreak.new
      end
    end

    def note_flowable(note)
      body = note.body.map { |paragraph| paragraph_flowable(paragraph) }
      Flowables::NoteFlowable.new(
        formatted_note_label(note.label),
        body,
        style: resolve(note.style_id),
        label_style: resolve(:note_label)
      )
    end

    def formatted_note_label(label)
      return '' if label.nil? || label.empty?

      suffix = @rules.dig('note', 'label_suffix') || ':'
      stripped = label.strip.chomp(':').strip
      return '' if stripped.empty?

      suffix.start_with?(':') ? "#{stripped}#{suffix} " : "#{stripped} #{suffix} "
    end

    # Examples render the label as a block heading with the body
    # indented 35.4pt — the FOP example layout.
    def example_flowable(example)
      body = example.body.map { |paragraph| paragraph_flowable(paragraph) }
      Flowables::NoteFlowable.new(
        example.label,
        body,
        style: resolve(example.style_id),
        body_indent: 35.4,
        label_mode: :block
      )
    end

    def figure_group_flowable(group, out)
      out << image_flowable(group.image) if group.image
      return unless group.caption

      caption_style = resolve(:figure_caption)
      runs = group.caption.inline_runs.map do |run|
        InlineRun.new(run.text, style: caption_style)
      end
      out << Flowables::TextFlowable.new(runs, style: caption_style)
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
      entry.definition.each { |item| append_child(item, out, standalone: false) }
      return unless entry.source

      source_style = resolve(entry.source.style_id).with(margin_top: 2.0, margin_bottom: 2.0)
      source_runs = entry.source.inline_runs.map do |run|
        InlineRun.new(run.text, style: resolve(run.style_id),
                                baseline_shift: run.baseline_shift,
                                font_size_scale: run.font_size_scale,
                                href: run.href)
      end
      out << Flowables::TextFlowable.new(source_runs, style: source_style)
    end

    def bibliography_item_flowable(item, out)
      tag = item.tag.to_s
      body_para = bibliography_body_paragraph(item)
      if tag.empty?
        out << paragraph_flowable(body_para)
        return
      end

      body = paragraph_flowable(body_para)
      out << Flowables::NoteFlowable.new(
        tag,
        [body],
        style: resolve(item.style_id || :bibitem),
        label_style: resolve(:bibitem_marker),
        marker_width: 24.0
      )
    end

    def bibliography_body_paragraph(item)
      runs = []
      if item.formattedref
        runs.concat(item.formattedref.inline_runs.map do |r|
          Content::InlineRun.new(r.text, style_id: r.style_id)
        end)
      end
      Content::Paragraph.new(runs, style_id: item.style_id || :bibitem,
                                   id: item.id)
    end

    def marker_width_of(tag)
      return 0.0 if tag.to_s.empty?

      style = resolve(:bibitem_marker)
      GlyphMeasurer.new(font_name: style.font_name)
                   .width_of_string("#{tag} ", font_size: style.font_size)
    end

    def table_caption_for(table)
      table.caption
    end

    # Table geometry (minimum row height, cell padding, footnote
    # size) is flavor configuration — extracted from the flavor's
    # XSL row/cell styles — not engine policy.
    def table_geometry
      config = @rules['table'] || {}
      {
        min_row_height: config.fetch('min_row_height', 0.0).to_f,
        cell_padding: config.fetch('cell_padding', 2.0).to_f,
        footnote_font_size: config['footnote_font_size']&.to_f
      }
    end

    def paragraph_flowable(paragraph, standalone: false)
      runs = paragraph.inline_runs.map do |run|
        InlineRun.new(
          run.text,
          style: resolve(run.style_id),
          baseline_shift: run.baseline_shift,
          font_size_scale: run.font_size_scale,
          href: run.href
        )
      end
      style = resolve(paragraph.style_id)
      style = style.with(margin_bottom: 10.0) if standalone && paragraph.style_id == :body
      Flowables::TextFlowable.new(runs, style: style)
    end

    def preformatted_flowable(preformatted)
      style = resolve(:preformatted)
      runs = preformatted.lines.flat_map.with_index do |line, index|
        line_runs = [InlineRun.new(line.empty? ? ' ' : line, style: style)]
        line_runs << InlineRun.new("\n", style: style) if index < preformatted.lines.length - 1
        line_runs
      end
      Flowables::TextFlowable.new(runs, style: style)
    end

    def list_flowable(list)
      items = list.items.each_with_index.map do |item, index|
        marker = item.marker.nil? ? default_marker(list, index) : item.marker
        body = item.content.flat_map do |content|
          flowable_for_list_content(content)
        end
        [marker, body]
      end
      Flowables::ListFlowable.new(items, kind: list.kind, style: resolve(list.style_id))
    end

    def flowable_for_list_content(content)
      case content
      when Content::Paragraph then [paragraph_flowable(content)]
      when Content::List then [list_flowable(content)]
      else []
      end
    end

    def default_marker(list, index)
      defaults = @rules.dig('list', 'defaults') || {}
      if list.ordered?
        format = defaults['ordered_marker'] || '%d.'
        format.sub('%d', (index + 1).to_s)
      else
        defaults['bullet_marker'] || '■ '
      end
    end

    def image_flowable(image)
      source = resolve_image_source(image)
      image_rules = @rules['image'] || {}
      default_width = (image_rules['default_natural_width'] || 400).to_f
      default_height = (image_rules['default_natural_height'] || 300).to_f
      max_width = (image_rules['max_display_width'] || 106).to_f
      natural_width = image.width || svg_dimension(source, 'width') || default_width
      natural_height = image.height || svg_dimension(source, 'height') || default_height
      display_width = [image.width || natural_width, max_width].min
      Flowables::ImageFlowable.new(
        source,
        natural_width: natural_width,
        natural_height: natural_height,
        display_width: display_width,
        alt: image.alt,
        style: resolve(image.style_id)
      )
    end

    def resolve_image_source(image)
      return asset_resolver.resolve(image.src) unless image.src.is_a?(String)
      return write_inline_svg(image.src) if image.src.start_with?(INLINE_SVG_PREFIX)

      asset_resolver.resolve(image.src)
    end

    def write_inline_svg(prefixed)
      svg_xml = prefixed[INLINE_SVG_PREFIX.length..]
      path = File.join(Dir.mktmpdir('arrolio-svg'), 'figure.svg')
      File.write(path, svg_xml)
      path
    end

    def svg_dimension(source, name)
      return nil unless source && File.exist?(source) && source.match?(/\.svg\z/i)

      value = File.read(source)[/(?:#{name})=["']([\d.]+)/, 1]
      value && (value.to_f * SVG_PX_TO_PT)
    end

    def resolve(style_id)
      @layout_spec.resolve_style(style_id.to_sym)
    end

    def condition_matches?(condition, document)
      return true if condition.nil?

      case condition.to_s
      when 'title_part_present' then !document.cover&.dig(:title_part).to_s.empty?
      when 'title_intro_present' then !document.cover&.dig(:title_intro).to_s.empty?
      when 'title_complementary_present' then !document.cover&.dig(:title_complementary).to_s.empty?
      else false
      end
    end

    def interpolate(template, document)
      return nil if template.nil?

      template.to_s.gsub(/\{\{([^}]+)\}\}/) do
        key = Regexp.last_match(1).strip.to_sym
        value = document.metadata[key] || document.cover&.dig(key)
        value.to_s
      end
    end
  end
end
