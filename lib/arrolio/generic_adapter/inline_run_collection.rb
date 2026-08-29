# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Extracted conversion seam (TODO 56): one module per concern,
    # included into the adapter. The class keeps dispatch and glue.
    module InlineRunCollection
    UNICODE_SPACES = Regexp.new("[\u00A0\u1680\u2000-\u200B\u202F\u205F\u3000\uFEFF]")
    def collect_inline_runs(elem, default_style: :inline, exclude: nil,
                            footnote_markers: false)
      runs = []
      stem_name = selector('stem')
      fn_name = footnote_markers ? selector('footnote_marker') : nil
      stem_formatted_name = selector('stem_formatted')
      math_name = selector('math')
      tab_name = selector('tab_inline')
      br_name = selector('break_inline')
      xref_name = selector('biblio_formattedref') ? 'fmt-xref' : nil
      skip_metadata = @rules['skip_metadata_elements'].to_a
      block_level = @rules['block_level_elements'].to_a
      inline_styles = @rules['inline_styles'] || {}

      walker = lambda do |node, style, baseline: Content::InlineRun::BASELINE_NORMAL, scale: 1.0, in_xref: false|
        case node
        when REXML::Text
          raw = normalize_text(node.value)
          next if raw.nil? || raw.empty?

          text = in_xref ? format_locality_text(raw) : raw
          runs << Content::InlineRun.new(text, style_id: style,
                                               baseline_shift: baseline,
                                               font_size_scale: scale)
        when REXML::Element
          next if exclude && node.name == exclude

          if fn_name && node.name == fn_name
            marker = node.attribute('reference')&.value ||
                     node.attribute('id')&.value
            unless marker.nil? || marker.empty?
              runs << Content::InlineRun.new(
                marker, style_id: style,
                        baseline_shift: Content::InlineRun::BASELINE_SUP,
                        font_size_scale: 0.7
              )
            end
            next
          end

          new_style = resolve_inline_style(node, style)
          sub_baseline, sub_scale = baseline_for_style(inline_styles, node,
                                                       baseline, scale)
          child_in_xref = in_xref || (xref_name && node.name == xref_name)
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
            node.children.each do |c|
 walker.call(c, new_style, baseline: sub_baseline, scale: sub_scale, in_xref: child_in_xref)
            end
          end
        end
      end
      elem.children.each { |c| walker.call(c, default_style) }
      runs
    end

    def format_locality_text(text)
      text.gsub(/([a-zA-Z]+)=/, '\\1 ')
    end

    def walk_stem(stem_elem, style, runs, formatted_name, math_name)
      target = find_first(stem_elem, formatted_name) || find_first(stem_elem, math_name)
      walk_math(target, style, runs) if target
    end

    # Walks a MathML tree emitting InlineRuns with appropriate
    # baseline_shift + font_size_scale. Delegates the actual MathML
    # parsing to the plurimath/mml gem via MathML::InlineRunExtractor,
    # keeping this adapter free of its own MathML grammar.
    def walk_math(elem, style, runs)
      return unless elem

      math_name = selector('math')
      math_elem = if elem.name == math_name
        elem
      else
        found = nil
        elem.each_recursive { |e| found = e if e.name == math_name && found.nil? }
        found
      end
      return unless math_elem

      math_xml = serialize_element_to_xml(math_elem)
      extracted = ::Arrolio::MathML::InlineRunExtractor.extract_from_xml(math_xml,
                                                                         base_style: style)
      runs.concat(extracted)
    end

    def serialize_element_to_xml(elem)
      io = StringIO.new(+'')
      REXML::Formatters::Default.new.write(elem, io)
      io.string
    end

    # Newline-bearing text nodes keep ONE space at each boundary:
    # 'where\n<stem>' must render 'where Y' — stripping the
    # trailing whitespace glued words to the following element and
    # made long formula runs unbreakable (clipped at the page
    # edge).
    def normalize_text(raw)
      return raw unless raw.is_a?(String)
      cleaned = raw.gsub(UNICODE_SPACES, ' ')
      return cleaned unless cleaned.include?("\n")

      stripped = cleaned.strip
      return cleaned.match?(/\s/) ? ' ' : nil if stripped.empty?

      lead = cleaned.match?(/\A\s/) ? ' ' : ''
      trail = cleaned.match?(/\s\z/) ? ' ' : ''
      lead + stripped.gsub(/\s+/, ' ') + trail
    end
    end
  end
end
