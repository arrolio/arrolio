# frozen_string_literal: true

module Arrolio
  class GenericFlowBuilder
    # Extracted emission seam: one module per content family, the
    # same pattern as GenericAdapter's decomposition. The class
    # keeps build(), dispatch, and shared helpers.
    module Sequences
      def page_sequences
        Array(@rules['page_sequences'])
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
    end
  end
end
