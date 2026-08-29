# frozen_string_literal: true

require 'tmpdir'
require 'yaml'

module Arrolio
  class GenericFlowBuilder
    autoload :Sequences, 'arrolio/generic_flow_builder/sequences'
    autoload :Terms, 'arrolio/generic_flow_builder/terms'
    autoload :Notes, 'arrolio/generic_flow_builder/notes'
    autoload :Figures, 'arrolio/generic_flow_builder/figures'
    autoload :Lists, 'arrolio/generic_flow_builder/lists'
    autoload :Bibliography, 'arrolio/generic_flow_builder/bibliography'
    autoload :Tables, 'arrolio/generic_flow_builder/tables'

    include Sequences
    include Terms
    include Notes
    include Figures
    include Lists
    include Bibliography
    include Tables


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


    private


    def title_block_space
      (@rules.dig('title', 'block_space') || 0.0).to_f
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
