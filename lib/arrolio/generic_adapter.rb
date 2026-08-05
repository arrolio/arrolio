# frozen_string_literal: true

require 'yaml'
require 'rexml/document'

module Arrolio
  # Generic, configuration-driven XML adapter. Reads a set of
  # declarative rules (YAML) that describe how to parse a specific
  # document format's presentation XML into a Content::Document.
  #
  # A flavor is defined entirely by:
  #
  #   adapter_rules.yml  — element selectors, mappings, style resolution
  #   layout_spec.yml    — styles, page templates, flows
  #   flow_rules.yml     — page sequence structure, cover layout
  #
  # No Ruby code is needed for a new flavor. The adapter has ZERO
  # hard-coded element names — every XML element/attribute the adapter
  # touches is named in the rules' `selectors` block.
  class GenericAdapter
    DEFAULT_SELECTORS = {
      'heading' => 'fmt-title',
      'heading_depth_attribute' => 'depth',
      'list_item' => 'li',
      'list_item_label' => 'fmt-name',
      'paragraph' => 'p',
      'term_number' => 'fmt-name',
      'term_preferred' => 'fmt-preferred',
      'term_definition' => 'fmt-definition',
      'term_source' => 'fmt-termsource',
      'note_label' => 'fmt-name',
      'figure_image' => 'image',
      'figure_caption' => 'fmt-name',
      'figure_caption_fallback' => 'name',
      'table_row' => 'tr',
      'table_cell' => ['td', 'th'].freeze,
      'table_header' => 'thead',
      'table_body' => 'tbody',
      'biblio_tag' => 'biblio-tag',
      'biblio_formattedref' => 'formattedref',
      'image_src_attribute' => 'src',
      'image_alt_attribute' => 'alt',
      'id_attribute' => 'id',
      'autonum_class' => 'fmt-autonum-delim',
      'stem' => 'stem',
      'stem_formatted' => 'fmt-stem',
      'math' => 'math',
      'preface_container' => 'preface',
      'preface_children' => ['clause', 'foreword'].freeze,
      'bibliography_container' => 'bibliography',
      'bibliography_reference' => 'references',
      'bibliography_item' => 'bibitem',
      'fallback_title' => 'title',
      'span' => 'span',
      'tab_inline' => 'tab',
      'break_inline' => 'br'
    }.freeze

    attr_reader :rules, :layout_spec, :selectors

    def initialize(rules:, layout_spec: nil)
      @rules = rules.is_a?(String) ? YAML.safe_load_file(rules) : rules
      @layout_spec = layout_spec
      @selectors = DEFAULT_SELECTORS.merge(@rules['selectors'] || {})
    end

    def convert(xml)
      xml = xml.read if xml.is_a?(IO) || xml.is_a?(StringIO)
      xml = xml.to_s.dup.force_encoding('UTF-8').scrub
      rexml = xml.is_a?(REXML::Document) ? xml : REXML::Document.new(xml)
      root = rexml.root

      Content::Document.new(
        metadata: extract_metadata(root),
        sections: extract_sections(root),
        preface: extract_preface(root),
        bibliography: extract_bibliography(root),
        cover: extract_cover(root),
        footnotes: extract_footnotes(root),
        title_block: extract_title_block(root)
      )
    end

    private

    def selector(key)
      @selectors[key]
    end

    # ---- Metadata extraction ----

    def extract_metadata(root)
      config = @rules['metadata'] || {}
      bibdata_path = config['root'] || 'bibdata'
      bibdata = find_first(root, bibdata_path)
      return {} unless bibdata

      result = {}
      (config['fields'] || {}).each do |key, xpath|
        value = text_of(find_first(bibdata, xpath))
        result[key.to_sym] = value if value && !value.empty?
      end
      result
    end

    def extract_cover(root)
      metadata = extract_metadata(root)
      config = @rules['cover'] || {}
      result = {}
      (config['fields'] || ['docidentifier', 'edition', 'title_main', 'title_part']).each do |field|
        result[field.to_sym] = metadata[field.to_sym] if metadata[field.to_sym]
      end
      result.empty? ? nil : result
    end

    # ---- Section extraction ----

    def extract_sections(root)
      sections_config = @rules['sections'] || {}
      container = sections_config['container'] || 'sections'
      sections_elem = find_first(root, container)
      return [] unless sections_elem

      children = []
      each_direct_child(sections_elem) do |child|
        next unless map_element(child.name, sections_elem) == 'section'

        children << convert_clause(child)
      end
      children
    end

    def extract_title_block(root)
      sections_config = @rules['sections'] || {}
      container = sections_config['container'] || 'sections'
      sections_elem = find_first(root, container)
      return nil unless sections_elem

      para_name = selector('paragraph')
      each_direct_child(sections_elem) do |child|
        next unless child.name == para_name

        cls = child.attribute('class')&.value
        title_style = (@rules['paragraph_styles'] || {})[cls]
        next unless title_style

        return Content::Paragraph.new(
          collect_inline_runs(child),
          style_id: title_style.to_sym,
          id: child.attribute(selector('id_attribute'))&.value
        )
      end
      nil
    end

    def extract_preface(root)
      preface_elem = find_first(root, selector('preface_container'))
      return [] unless preface_elem

      result = []
      each_element(preface_elem) do |child|
        next if child == preface_elem
        next unless Array(selector('preface_children')).include?(child.name)

        result << convert_clause(child)
      end
      result
    end

    def extract_footnotes(root)
      container_name = selector('footnote_container')
      body_name = selector('footnote_body')
      marker_name = selector('footnote_marker')
      return [] unless container_name && body_name

      footnotes = []
      each_element(root) do |elem|
        next unless elem.name == container_name

        marker = elem.attribute('id')&.value || elem.attribute(marker_name)&.value || ''
        body_elem = find_first(elem, body_name)
        body = []
        if body_elem
          para_name = selector('paragraph')
          each_element(body_elem) do |child|
            next unless child.name == para_name

            body << convert_paragraph(child)
          end
        end
        next if body.empty?

        footnotes << Content::Footnote.new(
          marker: marker,
          body: body,
          id: elem.attribute(selector('id_attribute'))&.value
        )
      end
      footnotes
    end

    def extract_bibliography(root)
      biblio_elem = find_first(root, selector('bibliography_container'))
      return [] unless biblio_elem

      result = []
      each_element(biblio_elem) do |child|
        next if child == biblio_elem
        next unless child.name == selector('bibliography_reference')

        items = []
        each_child(child, selector('bibliography_item')) { |bi| items << convert_bibitem(bi) }
        result << Content::Section.new(
          title: 'Bibliography',
          level: 1,
          children: items,
          style_id: :section_body_1,
          title_style_id: :heading_1
        )
      end
      result
    end

    # ---- Element converters (driven by rules) ----

    def convert_clause(elem)
      title, number = extract_heading(elem)
      children = convert_children(elem)
      level = clause_level(elem)
      Content::Section.new(
        title: title, level: level, number: number,
        id: elem.attribute(selector('id_attribute'))&.value, children: children,
        style_id: :"section_body_#{level}",
        title_style_id: :"heading_#{level}"
      )
    end

    def clause_level(elem)
      heading_name = selector('heading')
      depth_attr = selector('heading_depth_attribute')
      fmt_title = elem.elements.first { |e| e.name == heading_name }
      depth = fmt_title&.attribute(depth_attr)&.value.to_i
      [depth, 1].max
    end

    def convert_children(parent)
      children = []
      mapping = @rules['element_mapping'] || {}
      skip = @rules['skip_elements'] || []

      each_direct_child(parent) do |child|
        next if skip.include?(child.name)

        type = mapping[child.name]&.dig('content_type')
        next if type.nil?

        case type
        when 'section'
          children << convert_clause(child)
        when 'paragraph'
          children << convert_paragraph(child)
        when 'table'
          children << convert_table(child)
        when 'figure'
          children.concat(convert_figure(child))
        when 'list'
          children << convert_list(child, kind: mapping[child.name]['kind']&.to_sym || :bullet)
        when 'term'
          children.concat(convert_term(child))
        when 'note'
          children.concat(convert_note(child))
        when 'example'
          children.concat(convert_example(child))
        when 'preformatted'
          children << Content::Preformatted.new(
            text_of(child).split("\n", -1),
            style_id: :preformatted
          )
        end
      end
      children
    end

    def convert_paragraph(elem)
      runs = collect_inline_runs(elem)
      refs = extract_footnote_refs(elem)
      Content::Paragraph.new(runs, style_id: paragraph_style(elem),
                                   id: elem.attribute(selector('id_attribute'))&.value,
                                   footnote_refs: refs)
    end

    def extract_footnote_refs(elem)
      marker_name = selector('footnote_marker')
      return [] unless marker_name

      refs = []
      elem.each_recursive do |node|
        next unless node.is_a?(REXML::Element) && node.name == marker_name

        id = node.attribute('id')&.value ||
             node.attribute(selector('id_attribute'))&.value ||
             text_of(node)
        refs << id.to_s if id && !id.to_s.empty?
      end
      refs
    end

    def convert_table(elem)
      header = convert_table_rows(find_first(elem, selector('table_header')), true)
      body = convert_table_rows(find_first(elem, selector('table_body')), false)
      Content::Table.new(header: header, body: body, style_id: :table,
                         id: elem.attribute(selector('id_attribute'))&.value)
    end

    def convert_table_rows(parent, is_header)
      return [] unless parent

      rows = []
      row_name = selector('table_row')
      cell_names = Array(selector('table_cell'))
      each_child(parent, row_name) do |tr|
        cells = []
        each_element(tr) do |cell|
          next unless cell_names.include?(cell.name)

          runs = collect_inline_runs(cell)
          cells << Content::Table::Cell.new(
            [Content::Paragraph.new(runs, style_id: is_header ? :table_header_cell : :table_cell)],
            colspan: (cell.attribute('colspan')&.value || 1).to_i,
            rowspan: (cell.attribute('rowspan')&.value || 1).to_i,
            style_id: is_header ? :table_header_cell : :table_cell
          )
        end
        rows << Content::Table::Row.new(cells)
      end
      rows
    end

    def convert_list(elem, kind:)
      items = []
      item_name = selector('list_item')
      label_name = selector('list_item_label')
      para_name = selector('paragraph')
      each_child(elem, item_name) do |li|
        marker = nil
        label_elem = find_first(li, label_name)
        marker = text_of(label_elem) if label_elem

        paras = []
        each_element(li) do |child|
          next unless child.name == para_name

          paras << convert_paragraph(child)
        end
        content = paras.empty? ? [Content::Paragraph.new(collect_inline_runs(li))] : paras
        items << Content::List::Item.new(content, marker: marker)
      end
      Content::List.new(items, kind: kind, style_id: kind == :ordered ? :list_ordered : :list_bullet)
    end

    def convert_figure(elem)
      image_name = selector('figure_image')
      src_attr = selector('image_src_attribute')
      alt_attr = selector('image_alt_attribute')
      image_elem = find_direct_child(elem, image_name)
      image = nil
      if image_elem
        src = image_elem.attribute(src_attr)&.value
        if src && !src.empty?
          image = Content::Image.new(src,
                                     alt: image_elem.attribute(alt_attr)&.value,
                                     id: image_elem.attribute(selector('id_attribute'))&.value)
        end
      end
      name = find_first(elem, selector('figure_caption')) ||
             find_first(elem, selector('figure_caption_fallback'))
      caption = nil
      if name
        runs = collect_inline_runs(name)
        caption = Content::Paragraph.new(runs, style_id: :figure_caption) unless runs.empty?
      end
      return [] if image.nil? && caption.nil?

      [Content::FigureGroup.new(image: image, caption: caption, id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def convert_term(elem)
      number = nil
      number_elem = find_first(elem, selector('term_number'))
      number = text_of(number_elem).strip if number_elem
      number = nil if number && number.empty?

      preferred = nil
      preferred_elem = find_first(elem, selector('term_preferred'))
      if preferred_elem
        runs = collect_inline_runs(preferred_elem, default_style: :term)
        preferred = Content::Paragraph.new(runs, style_id: :term) unless runs.empty?
      end

      definition = []
      definition_elem = find_first(elem, selector('term_definition'))
      if definition_elem
        para_name = selector('paragraph')
        REXML::XPath.each(definition_elem, ".//#{para_name}") do |p|
          next unless p.is_a?(REXML::Element)

          definition << convert_paragraph(p)
        end
      end

      source = nil
      source_elem = find_first(elem, selector('term_source'))
      if source_elem
        runs = collect_inline_runs(source_elem, default_style: :bibitem)
        source = Content::Paragraph.new(runs, style_id: :bibitem) unless runs.empty?
      end

      return [] if number.nil? && preferred.nil? && definition.empty? && source.nil?

      [Content::TermEntry.new(number: number, preferred: preferred,
                              definition: definition, source: source,
                              id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def convert_note(elem)
      label_elem = find_first(elem, selector('note_label'))
      label = label_elem ? text_of(label_elem).strip : ''

      para_name = selector('paragraph')
      body = []
      each_element(elem) do |child|
        next unless child.name == para_name

        body << convert_paragraph(child)
      end
      return [] if body.empty?

      [Content::Note.new(label: label, body: body, id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def convert_example(elem)
      label_elem = find_first(elem, selector('note_label'))
      label = label_elem ? text_of(label_elem).strip : ''

      para_name = selector('paragraph')
      body = []
      each_element(elem) do |child|
        next unless child.name == para_name

        body << convert_paragraph(child)
      end
      return [] if body.empty?

      [Content::Example.new(label: label, body: body, id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def convert_bibitem(bi)
      tag_name = selector('biblio_tag')
      tag = find_first(bi, tag_name)
      tag_text = nil
      if tag
        tag_runs = collect_inline_runs(tag, default_style: :bibitem)
        replacement = (@rules['tab_replacements'] || {})[tag.name] || "\t"
        tag_runs.map! { |r| r.text == "\t" ? Content::InlineRun.new(replacement, style_id: r.style_id) : r }
        tag_text = tag_runs.map(&:text).join.strip
      end
      formattedref = find_first(bi, selector('biblio_formattedref'))
      ref_paragraph = nil
      if formattedref
        runs = collect_inline_runs(formattedref)
        ref_paragraph = Content::Paragraph.new(runs, style_id: :bibitem) unless runs.empty?
      end
      return [] if tag_text.nil? && ref_paragraph.nil?

      [Content::BibliographyItem.new(tag: tag_text, formattedref: ref_paragraph,
                                     id: bi.attribute(selector('id_attribute'))&.value)]
    end

    # ---- Inline run collection (driven by rules) ----

    def collect_inline_runs(elem, default_style: :inline)
      runs = []
      stem_name = selector('stem')
      stem_formatted_name = selector('stem_formatted')
      math_name = selector('math')
      tab_name = selector('tab_inline')
      br_name = selector('break_inline')
      skip_metadata = @rules['skip_metadata_elements'].to_a
      block_level = @rules['block_level_elements'].to_a

      walker = lambda do |node, style|
        case node
        when REXML::Text
          text = normalize_text(node.value)
          next if text.nil? || text.empty?

          runs << Content::InlineRun.new(text, style_id: style)
        when REXML::Element
          new_style = resolve_inline_style(node, style)
          case node.name
          when tab_name
            runs << Content::InlineRun.new("\t", style_id: style)
          when br_name
            runs << Content::InlineRun.new("\n", style_id: style)
          when stem_name
            unless sibling_exists?(node.parent, stem_formatted_name)
              walk_stem(node, style, runs, stem_formatted_name, math_name)
            end
          when stem_formatted_name
            walk_math(node, style, runs)
          when *skip_metadata
            next
          when *block_level
            next
          else
            node.children.each { |c| walker.call(c, new_style) }
          end
        end
      end
      elem.children.each { |c| walker.call(c, default_style) }
      runs
    end

    def resolve_inline_style(elem, current)
      styles = @rules['inline_styles'] || {}
      mapped = styles[elem.name]
      return mapped.to_sym if mapped

      if elem.name == selector('span')
        span_styles = @rules['span_class_styles'] || {}
        cls = elem.attribute('class')&.value
        mapped = span_styles[cls]
        return mapped.to_sym if mapped
      end
      current
    end

    def walk_stem(stem_elem, style, runs, formatted_name, math_name)
      target = find_first(stem_elem, formatted_name) || find_first(stem_elem, math_name)
      walk_math(target, style, runs) if target
    end

    def walk_math(elem, style, runs)
      return unless elem

      elem.each_recursive do |child|
        next unless child.is_a?(REXML::Text)

        text = normalize_text(child.value)
        next if text.nil? || text.empty?

        runs << Content::InlineRun.new(text, style_id: style)
      end
    end

    # ---- Heading extraction ----

    def extract_heading(clause)
      heading_config = @rules['heading'] || {}
      source = heading_config['source'] || selector('heading')
      heading_elem = find_first(clause, source)
      if heading_elem
        extract_from_heading(heading_elem)
      else
        title = find_first(clause, selector('fallback_title'))
        [title ? text_of(title) : nil, nil]
      end
    end

    def extract_from_heading(heading_elem)
      parts = []
      number_parts = []
      title_parts = []
      non_number_parts = []
      autonum_class = selector('autonum_class')
      autonum_delim_class = selector('autonum_delim_class') || 'fmt-autonum-delim'
      caption_label_class = selector('caption_label_class') || 'fmt-caption-label'

      walk_heading_text(heading_elem) do |text, parent|
        parts << text
        element_attr = parent&.attribute('element')&.value
        parent_class = parent&.attribute('class')&.value
        if element_attr == 'autonum' ||
           parent_class == autonum_class ||
           parent_class == autonum_delim_class ||
           parent_class == caption_label_class
          number_parts << text
        elsif element_attr == 'title'
          title_parts << text
          non_number_parts << text
        else
          non_number_parts << text
        end
      end

      number = number_parts.join.strip
      number = nil if number.empty?

      title = if title_parts.any?
                title_parts.join.strip
              elsif parts.include?("\t")
                parts.join.split("\t", 2).last&.strip
              else
                non_number_parts.join.strip
              end
      title = nil if title.nil? || title.empty?
      [title, number]
    end

    def walk_heading_text(element, &block)
      element.children.each do |child|
        case child
        when REXML::Text
          yield(child.value, child.parent)
        when REXML::Element
          walk_heading_text(child, &block)
        end
      end
    end

    # ---- Text helpers ----

    def normalize_text(raw)
      return raw unless raw.is_a?(String)
      return raw unless raw.include?("\n")

      stripped = raw.strip
      return raw.match?(/ /) ? ' ' : nil if stripped.empty?

      stripped.gsub(/\s+/, ' ')
    end

    def text_of(elem)
      return '' unless elem

      collect_text(elem).strip
    end

    def collect_text(node)
      case node
      when REXML::Text then node.value
      when REXML::Element then node.children.map { |c| collect_text(c) }.join
      else ''
      end
    end

    # ---- XML traversal helpers ----

    def find_first(parent, path)
      return nil unless parent

      nodes = [parent]
      path.to_s.split('/').each do |segment|
        name = segment[/\A[^\[]+/]
        predicate = segment.match(/\[@([^=]+)=['"]([^'"]+)['"]\]/)
        nodes = nodes.flat_map do |node|
          node.elements.to_a.select do |element|
            next false unless element.name == name
            predicate.nil? || element.attribute(predicate[1])&.value == predicate[2]
          end
        end
      end
      nodes.first
    end

    def find_direct_child(parent, name)
      return nil unless parent

      parent.children.each do |c|
        return c if c.is_a?(REXML::Element) && c.name == name
      end
      nil
    end

    def each_direct_child(parent)
      return enum_for(:each_direct_child, parent) unless block_given?
      return unless parent

      parent.children.each { |c| yield c if c.is_a?(REXML::Element) }
    end

    def each_child(parent, name)
      return enum_for(:each_child, parent, name) unless block_given?
      return unless parent

      parent.elements.each { |e| yield e if e.name == name }
    end

    def each_element(parent, &block)
      return enum_for(:each_element, parent) unless block_given?
      return unless parent

      parent.each_element(&block)
    end

    def sibling_exists?(parent, name)
      return false unless parent.is_a?(REXML::Element)

      parent.each_element { |e| return true if e.name == name }
      false
    end

    def has_class?(elem, cls)
      elem.attribute('class')&.value&.start_with?(cls)
    end

    def paragraph_style(elem)
      cls = elem.attribute('class')&.value
      style_map = @rules['paragraph_styles'] || {}
      style_map[cls] || :body
    end

    def map_element(name, _parent)
      mapping = @rules['element_mapping'] || {}
      mapping[name]&.dig('content_type')
    end
  end
end
