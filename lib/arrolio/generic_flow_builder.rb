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

        start = sequence_start(document, sequence)
        flowables << start
        # The part-title overlay consumes layout space in the
        # reference (title glyph top to the first heading: 58pt on
        # the first body page); reserve it so following content
        # lands where the reference puts it.
        flowables << Flowables::Spacer.new(title_block_space) if start.title_template
        build_sequence_content(document, source, sequence, flowables)
        flowables << Flowables::PageBreak.new if sequence['page_break_after']
      end
      append_endnotes(document, flowables)
      flowables
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

    def title_block_space
      (@rules.dig('title', 'block_space') || 0.0).to_f
    end

    def sequence_start(document, sequence)
      title = sequence['role'].to_s == 'body' ? title_text(document) : nil
      Flowables::PageSequenceStart.new(
        role: sequence.fetch('role'),
        header_template: interpolate(sequence['header'], document),
        footer_template: sequence['footer'],
        header_align: sequence['header_align'],
        footer_align: sequence['footer_align'] || :center,
        initial_page_number: sequence['initial_page_number'],
        title_template: title
      )
    end

    def build_sequence_content(document, source, sequence, out)
      if sequence['build_content'] == 'cover_content'
        build_cover_content(document, out)
      elsif source.is_a?(Array)
        build_sections(source, out,
                       between_breaks: preface_clause_breaks?(sequence))
      end
    end

    # mn2pdf gives each preface clause its own page sequence (ToC
    # page, then Foreword on a fresh page) when the flavor opts in.
    def preface_clause_breaks?(sequence)
      sequence['role'].to_s == 'preface' &&
        @rules.dig('preface', 'page_break_between_clauses')
    end

    # The first body page opens with the part title ("Part 1 -
    # {part title}") - the docidentifier's trailing part number
    # supplies the prefix.
    def title_text(document)
      return nil unless document.title_block

      text = document.title_block.inline_runs.map(&:text).join.strip
      return nil if text.empty?

      part = document.metadata[:docidentifier].to_s[/-(\d+)\z/, 1]
      part ? "Part #{part} - #{text}" : text
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

    def build_sections(sections, out, between_breaks: false)
      section_rules = @rules.fetch('section', {})
      break_between = section_rules.fetch('insert_page_break_before', false)
      break_numbers = section_rules.fetch('page_break_before_numbers', [])
      sections.each_with_index do |section, index|
        forced = break_numbers.include?(section.number.to_s)
        needs_break = (break_between || forced || between_breaks) &&
                      index.positive? && !bibliography_section?(section)
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
      children.each_with_index do |child, index|
        append_child(child, out, followed_by_keep: keeps_with_previous?(children[index + 1]))
      end
    end

    # Tables and lists pull their preceding paragraph with them
    # across page boundaries (XSL-FO keep-with-next on the lead-in;
    # the reference breaks freely between text and figures — 2.3's
    # paragraph ends p5 with Figure 1 opening p6).
    def keeps_with_previous?(child)
      child.is_a?(Content::Table) || child.is_a?(Content::List)
    end

    def prefix_number(number, children)
      return children if children.empty? || !children.first.is_a?(Content::Paragraph)

      first = children.first
      prefix = Content::InlineRun.new("#{number} ", style_id: :caption_label)
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
      return unless @rules['page_bottom_footnotes']
      return unless @document

      paragraph.footnote_refs.each do |ref_id|
        footnote = @document.footnotes.find { |fn| fn.id == ref_id || fn.marker == ref_id }
        next unless footnote

        out << Flowables::FootnoteMarkerFlowable.new(
          footnote, style: resolve(:footnote)
        )
      end
    end

    def append_child(child, out, standalone: true, followed_by_keep: false,
                     in_term: false)
      case child
      when Content::Paragraph
        flowable = paragraph_flowable(child, standalone: standalone)
        # mn2pdf keeps a paragraph with the table/figure that
        # follows it, so the caption is never orphaned at a page
        # bottom and the reference's page-end whitespace before
        # table sections is reproduced.
        if followed_by_keep
          flowable = Flowables::TextFlowable.new(
            flowable.runs,
            style: flowable.style.with(keep_with_next: true),
            measurer: flowable.measurer
          )
        end
        out << flowable
        emit_footnote_markers_for(child, out)
      when Content::Note
        note = note_flowable(child)
        before = in_term ? term_config.fetch('note_spacing', 0.0).to_f : 0.0
        after = in_term ? term_config.fetch('note_spacing_after', before) : 0.0
        parts = []
        parts << Flowables::Spacer.new(before) if before.positive?
        parts << note
        parts << Flowables::Spacer.new(after) if after.positive?
        out << if parts.length == 1
                 note
               else
                 Flowables::GroupFlowable.new(parts,
                                              style: Style::Definition.new(keep_together: false))
               end
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
        out << Flowables::TableFlowable.new(child,
                                            style: resolve(child.style_id),
                                            caption_runs: caption_runs_for(child),
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
      body = note.body.map { |node| note_body_flowable(node) }
      body = with_note_body_spacing(body)
      Flowables::NoteFlowable.new(
        formatted_note_label(note.label),
        body,
        style: resolve(note.style_id),
        label_style: resolve(:note_label)
      )
    end

    # A note's trailing list sits ~7pt below its text in the
    # reference (3.1.3.1: text -> list 20pt vs a plain 13pt pitch).
    def with_note_body_spacing(body)
      spacing = (@rules.dig('note', 'body_spacing') || 0.0).to_f
      return body if spacing.zero? || body.length < 2

      body.flat_map.with_index do |flowable, index|
        index < body.length - 1 ? [flowable, Flowables::Spacer.new(spacing)] : [flowable]
      end
    end

    def note_body_flowable(node)
      return list_flowable(node, container: :note) if node.is_a?(Content::List)

      paragraph_flowable(node)
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

    # Figures are atomic: image + caption render as ONE flowable
    # so the caption can never be orphaned onto the next page.
    # Caption gap is flavor geometry (ref: image bottom to caption
    # ~28pt; figure blocks separated by ~24pt).
    def figure_group_flowable(group, out)
      figure_config = @rules['figure'] || {}
      caption_gap = figure_config.fetch('caption_gap', 0.0).to_f
      block_gap = figure_config.fetch('block_gap', 0.0).to_f

      image = image_flowable(group.image) if group.image
      if group.caption
        caption_style = resolve(:figure_caption).with(margin_top: caption_gap)
        runs = group.caption.inline_runs.map do |run|
          InlineRun.new(run.text, style: caption_style)
        end
        caption = Flowables::TextFlowable.new(runs, style: caption_style)
      end
      return out << caption if image.nil?

      image = with_block_gap(image, block_gap)
      out << if caption
               Flowables::FigureFlowable.new(image, caption)
             else
               image
             end
    end

    def with_block_gap(flowable, gap)
      return flowable if gap.zero?

      style = flowable.style.with(margin_top: flowable.style.margin_top + gap)
      flowable.class.new(flowable.src,
                         natural_width: flowable.natural_width,
                         natural_height: flowable.natural_height,
                         display_width: flowable.display_width,
                         alt: flowable.alt,
                         style: style)
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

    def caption_runs_for(table)
      return nil if table.caption.nil?

      paragraph_flowable(table.caption, standalone: false).runs
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

    def list_flowable(list, container: nil)
      items = list.items.each_with_index.map do |item, index|
        marker = item.marker.nil? ? default_marker(list, index, container: container) : item.marker
        body = item.content.flat_map do |content|
          flowable_for_list_content(content)
        end
        [marker, body]
      end
      Flowables::ListFlowable.new(items, kind: list.kind,
                                         style: resolve(list.style_id),
                                         **list_geometry(list.kind, container: container))
    end

    # List marker geometry (indent, marker column, inter-item
    # spacing) is flavor configuration extracted from the flavor's
    # XSL list styles — not engine policy.
    # A kind-specific map (e.g. geometry.ordered) overrides the
    # shared defaults — flavors whose bullets indent but whose
    # ordered markers start at the margin (which also restores
    # nested lists' depth).
    def list_geometry(kind, container: nil)
      config = @rules.dig('list', 'geometry') || {}
      config = config.merge(config[kind.to_s] || {})
      # Lists nested in note bodies sit deeper: the reference puts
      # 3.1.3.1's note bullets at +43.7pt from the note column
      # (marker x=143 from the page), pitch 17pt.
      config = config.merge(@rules.dig('note', 'list') || {}) if container == :note
      {
        marker_indent: config.fetch('marker_indent', 0.0).to_f,
        marker_width: config.fetch('marker_width', 18.0).to_f,
        body_indent: config.fetch('body_indent', 6.0).to_f,
        item_spacing: config.fetch('item_spacing', 0.0).to_f
      }
    end

    def flowable_for_list_content(content)
      case content
      when Content::Paragraph then [paragraph_flowable(content)]
      when Content::List then [list_flowable(content)]
      else []
      end
    end

    def default_marker(list, index, container: nil)
      defaults = @rules.dig('list', 'defaults') || {}
      if list.ordered?
        format = defaults['ordered_marker'] || '%d.'
        format.sub('%d', (index + 1).to_s)
      else
        nested = @rules.dig('note', 'list') || {}
        return nested['bullet_marker'] if container == :note && nested['bullet_marker']

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
