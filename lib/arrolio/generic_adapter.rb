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
    autoload :InlineRunCollection, 'arrolio/generic_adapter/inline_run_collection'
    autoload :HeadingExtraction, 'arrolio/generic_adapter/heading_extraction'
    autoload :ListConversion, 'arrolio/generic_adapter/list_conversion'
    autoload :MetadataExtraction, 'arrolio/generic_adapter/metadata_extraction'
    autoload :DocumentExtraction, 'arrolio/generic_adapter/document_extraction'
    autoload :FootnoteExtraction, 'arrolio/generic_adapter/footnote_extraction'

    include FootnoteExtraction
    include InlineRunCollection
    include HeadingExtraction
    include ListConversion
    include MetadataExtraction
    include DocumentExtraction

    autoload :TableConversion, 'arrolio/generic_adapter/table_conversion'

    include TableConversion

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

    # Maps content_type (declared in rules.element_mapping) to a
    # builder method. Adding a new content type = adding one entry
    # here plus a builder method below — convert_children itself
    # never needs to change (Open/Closed Principle).
    CONVERTER_REGISTRY = {
      'section' => :convert_section,
      'paragraph' => :convert_paragraph,
      'table' => :convert_table,
      'figure' => :convert_figure,
      'list' => :convert_list,
      'term' => :convert_term,
      'note' => :convert_note,
      'example' => :convert_example,
      'preformatted' => :convert_preformatted
    }.freeze

    XREF_ELEMENTS = ['fmt-xref-label', 'fmt-xref', 'xref'].freeze


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




    # ---- Section extraction ----





    # Context-specific title styles (e.g. the XSL rule "level-1
    # titles inside the preface are centered") live in the flavor's
    # `title_styles:` map keyed "{context}_{level}" — no core
    # knowledge of any flavor's heading look.
    def title_style_for(context, level)
      configured = @rules.dig('title_styles', "#{context}_#{level}")
      return :"heading_#{level}" unless configured

      configured.to_sym
    end


    # ---- Element converters (driven by rules) ----

    def convert_clause(elem, context: 'body')
      title, number = extract_heading(elem)
      children = convert_children(elem)
      level = clause_level(elem, number: number)
      Content::Section.new(
        title: title, level: level, number: number,
        id: elem.attribute(selector('id_attribute'))&.value, children: children,
        style_id: :"section_body_#{level}",
        title_style_id: title_style_for(context, level)
      )
    end


    # Maps content_type (declared in rules.element_mapping) to a
    # Each builder accepts a child element and returns one or more
    # Content nodes. The dispatch_converter helper wraps single
    # returns in an Array so the caller can always concat.
    private

    def convert_children(parent)
      children = []
      mapping = @rules['element_mapping'] || {}
      skip = @rules['skip_elements'] || []

      each_direct_child(parent) do |child|
        next if skip.include?(child.name)

        type = mapping[child.name]&.dig('content_type')
        next if type.nil?

        converter = CONVERTER_REGISTRY[type]
        next unless converter

        children.concat(dispatch_converter(converter, child, mapping[child.name]))
        next unless type == 'paragraph'

        children.concat(extract_embedded_blocks(child))
      end
      children
    end

    def extract_embedded_blocks(elem)
      extractor = Arrolio::EmbeddedBlockExtractor.new(@rules, CONVERTER_REGISTRY)
      extractor.extract(elem) do |converter, descendant, mapping_entry|
        dispatch_converter(converter, descendant, mapping_entry)
      end
    end

    # Routes to a converter. 'list' needs the kind argument pulled
    # from the mapping entry; all others take just the child.
    def dispatch_converter(converter, child, mapping_entry)
      if converter == :convert_list
        result = send(converter, child, kind: mapping_entry['kind']&.to_sym || :bullet)
        result.is_a?(Array) ? result : [result]
      elsif converter == :convert_preformatted
        [send(converter, child)]
      else
        result = send(converter, child)
        result.is_a?(Array) ? result : [result]
      end
    end

    def convert_preformatted(child)
      Content::Preformatted.new(
        text_of(child).split("\n", -1),
        style_id: :preformatted
      )
    end

    def convert_section(child)
      convert_clause(child)
    end

    # A paragraph's <fn> reference contributes only its marker; the
    # body renders in the page's footnote zone (engine collects
    # FootnoteMarkerFlowables per page). Inlining the body into the
    # runs doubles the text and displaces the flow.
    def convert_paragraph(elem)
      runs = collect_inline_runs(elem, footnote_markers: true)
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

    def convert_figure(elem)
      image = extract_figure_image(elem)
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

    def extract_figure_image(elem)
      image_name = selector('figure_image')
      image_elem = find_direct_child(elem, image_name)

      if image_elem
        svg_elem = nil
        image_elem.each_recursive { |e| svg_elem = e if e.name == 'svg' && svg_elem.nil? }
        if svg_elem
          svg_xml = serialize_element_to_xml(svg_elem)
          width, height = svg_viewbox_dimensions(svg_elem)
          return Content::Image.new(
            "inline-svg:#{svg_xml}",
            width: width,
            height: height,
            id: image_elem.attribute(selector('id_attribute'))&.value
          )
        end

        src = image_elem.attribute(selector('image_src_attribute'))&.value
        return nil if src.nil? || src.empty?

        return Content::Image.new(
          src,
          alt: image_elem.attribute(selector('image_alt_attribute'))&.value,
          id: image_elem.attribute(selector('id_attribute'))&.value
        )
      end

      svg_elem = nil
      elem.each_recursive { |e| svg_elem = e if e.name == 'svg' && svg_elem.nil? }
      return nil unless svg_elem

      svg_xml = serialize_element_to_xml(svg_elem)
      width, height = svg_viewbox_dimensions(svg_elem)
      Content::Image.new(
        "inline-svg:#{svg_xml}",
        width: width,
        height: height,
        id: elem.attribute(selector('id_attribute'))&.value
      )
    end

    def svg_viewbox_dimensions(svg_elem)
      viewbox = svg_elem.attribute('viewBox')&.value
      return [nil, nil] unless viewbox

      parts = viewbox.split(/\s+/)
      return [nil, nil] unless parts.length == 4

      # SVG user units are CSS pixels (96dpi); layout works in PDF
      # points (72dpi). FOP applies this factor to viewport-less
      # SVGs, so figures come out a third smaller than their raw
      # viewBox numbers.
      width = parts[2].to_f * (72.0 / 96.0)
      height = parts[3].to_f * (72.0 / 96.0)
      width.positive? ? [width, height] : [nil, nil]
    end

    def nested_in_term?(node, boundary)
      ancestor = node.parent
      while ancestor && ancestor != boundary
        return true if ancestor.name == 'term'

        ancestor = ancestor.parent
      end
      false
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
        # Only paragraphs of THIS term: nested <term> entries are
        # converted separately, and their paragraphs must not be
        # swallowed into the parent definition.
        REXML::XPath.each(definition_elem, ".//#{para_name}") do |p|
          next unless p.is_a?(REXML::Element)
          next if p.parent != definition_elem && nested_in_term?(p, definition_elem)

          definition << convert_paragraph(p)
          extract_embedded_blocks(p).each { |block| definition << block }
        end
      end

      source = nil
      source_elem = find_first(elem, selector('term_source'))
      if source_elem
        runs = collect_inline_runs(source_elem, default_style: :bibitem)
        source = Content::Paragraph.new(runs, style_id: :bibitem) unless runs.empty?
      end

      # A termnote belongs to its entry (rendered inside it, with
      # the entry's note styling) — not as a sibling block.
      nested = []
      each_element(elem) do |child|
        next unless child.parent == elem

        case child.name
        when 'termnote'
          definition.concat(convert_note(child))
        when elem.name
          # Nested terms (e.g. 3.1.3.1-3.1.3.4 under "load cell")
          # are entries in their own right; dropping them loses whole
          # definitions.
          nested.concat(convert_term(child))
        end
      end

      return [] if number.nil? && preferred.nil? && definition.empty? && source.nil?

      entry = Content::TermEntry.new(number: number, preferred: preferred,
                                     definition: definition, source: source,
                                     id: elem.attribute(selector('id_attribute'))&.value)
      [entry] + nested
    end

    # A note's body is paragraphs PLUS embedded lists (a termnote
    # may end in a bullet list of capabilities, for example) - the
    # list elements are siblings of the paragraphs, not children.
    def convert_note(elem)
      label_elem = find_first(elem, selector('note_label'))
      label = label_elem ? text_of(label_elem).strip : ''

      para_name = selector('paragraph')
      body = []
      each_element(elem) do |child|
        case child.name
        when para_name
          body << convert_paragraph(child)
          extract_embedded_blocks(child).each { |block| body << block }
        when 'ul', 'ol'
          dispatch_list(child, body)
        end
      end
      return [] if body.empty?

      [Content::Note.new(label: label, body: body, id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def dispatch_list(elem, body)
      mapping_entry = (@rules['element_mapping'] || {})[elem.name]
      kind = mapping_entry&.fetch('kind', nil)&.to_sym || :bullet
      converted = convert_list(elem, kind: kind)
      body.concat(converted.is_a?(Array) ? converted : [converted])
    end

    # An example renders its label as a block heading ("Example:"),
    # so the label is the localized element name only — the autonum
    # in fmt-name belongs to cross-references, not the display.
    def convert_example(elem)
      label_elem = find_first(elem, selector('note_label'))
      label = element_name_text(label_elem) || (label_elem ? text_of(label_elem).strip : '')

      para_name = selector('paragraph')
      body = []
      each_element(elem) do |child|
        next unless child.name == para_name

        para = convert_paragraph(child)
        # Example bodies take the example style (leading, indents) —
        # the source paragraphs carry the generic inline style.
        body << Content::Paragraph.new(para.inline_runs, style_id: :example,
                                                         id: para.id,
                                                         footnote_refs: para.footnote_refs)
      end
      return [] if body.empty?

      [Content::Example.new(label: label, body: body, id: elem.attribute(selector('id_attribute'))&.value)]
    end

    def element_name_text(label_elem)
      return nil unless label_elem

      name_class = selector('element_name')
      return nil unless name_class

      span = nil
      label_elem.each_recursive do |node|
        next unless node.is_a?(REXML::Element) && node.name == selector('span') &&
                    node.attribute('class')&.value == name_class

        span = node
        break
      end
      span ? text_of(span).strip : nil
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



    def baseline_for_style(rules, element, current_baseline, current_scale)
      mapping = rules[element.name]
      return [current_baseline, current_scale] unless mapping

      case mapping.to_sym
      when :subscript
        [Content::InlineRun::BASELINE_SUB, (current_scale * 0.7).round(4)]
      when :superscript
        [Content::InlineRun::BASELINE_SUP, (current_scale * 0.7).round(4)]
      else
        [current_baseline, current_scale]
      end
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




    # ---- Heading extraction ----




    # ---- Text helpers ----



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
