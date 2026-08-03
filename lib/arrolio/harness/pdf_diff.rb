# frozen_string_literal: true

require 'open3'

module Arrolio
  module Harness
    class PdfDiff
      Result = Struct.new(:ours_pages, :theirs_pages, :page_count_delta,
                          :per_page, :overall_similarity, keyword_init: true)

      PageResult = Struct.new(:number, :ours_text, :theirs_text,
                              :similarity, :missing, :extra, keyword_init: true)

      attr_reader :ours_path, :theirs_path

      def initialize(ours_path, theirs_path)
        @ours_path = ours_path
        @theirs_path = theirs_path
      end

      def call
        ours = pages_of(@ours_path)
        theirs = pages_of(@theirs_path)
        per_page = []
        max_len = [ours.length, theirs.length].max
        (1..max_len).each do |n|
          ot = ours[n - 1] || ''
          tt = theirs[n - 1] || ''
          matches = TextDiff.match_paragraphs(ot, tt)
          sim = if ot.empty? && tt.empty?
                  1.0
                elsif ot.empty? || tt.empty?
                  0.0
                else
                  matches.sum { |m| m[:similarity] } / [matches.length, 1].max
                end
          missing = matches.select { |m| m[:theirs].nil? }.map { |m| m[:ours] }
          extra = TextDiff.paragraphs(tt).reject { |p| matches.any? { |m| m[:theirs] == p } }
          per_page << PageResult.new(number: n, ours_text: ot, theirs_text: tt,
                                     similarity: sim, missing: missing, extra: extra)
        end
        overall = per_page.empty? ? 0.0 : per_page.sum(&:similarity) / per_page.length
        Result.new(ours_pages: ours.length, theirs_pages: theirs.length,
                   page_count_delta: ours.length - theirs.length,
                   per_page: per_page, overall_similarity: overall)
      end

      def report(max_per_page: 3)
        r = call
        lines = []
        lines << format('ours: %d pages, theirs: %d pages (delta %+d)',
                        r.ours_pages, r.theirs_pages, r.page_count_delta)
        lines << format('overall similarity: %.1f%%', r.overall_similarity * 100)
        lines << ''
        r.per_page.each do |page|
          lines << format('Page %d: similarity %.1f%%  (missing %d, extra %d)',
                          page.number, page.similarity * 100,
                          page.missing.length, page.extra.length)
          next unless page.similarity < 0.95

          page.missing.first(max_per_page).each { |t| lines << "  MISSING: #{truncate(t, 100)}" }
          page.extra.first(max_per_page).each { |t| lines << "  EXTRA:   #{truncate(t, 100)}" }
        end
        lines.join("\n") + "\n"
      end

      private

      def pages_of(path)
        if pdftotext_available?
          pages_via_pdftotext(path)
        else
          pages_via_pdfrb(path)
        end
      end

      def pdftotext_available?
        @pdftotext_available ||= system('which pdftotext > /dev/null 2>&1')
      end

      def pages_via_pdftotext(path)
        out, _status = Open3.capture2('pdftotext', '-enc', 'UTF-8', path, '-')
        out.split("\f").map(&:dup)
      rescue StandardError
        []
      end

      def pages_via_pdfrb(path)
        require 'stringio'
        bytes = File.binread(path)
        doc = Pdfrb::Document.new(io: StringIO.new(bytes))
        Pdfrb::Task::ExtractText.call(doc)
      rescue StandardError => e
        Arrolio::Logger.warn "PdfDiff: failed to read #{path}: #{e.class}: #{e.message}"
        []
      end

      def truncate(text, max)
        text = text.to_s.dup.force_encoding('UTF-8').scrub.gsub(/\s+/, ' ').strip
        text.length > max ? "#{text[0, max]}…" : text
      end
    end
  end
end
