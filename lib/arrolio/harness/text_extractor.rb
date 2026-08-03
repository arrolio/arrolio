# frozen_string_literal: true

require 'open3'

module Arrolio
  module Harness
    # Extracts text from PDF files for diff/matching. Uses poppler's
    # +pdftotext+ as the primary backend (reliable with CIDFont
    # subsets); falls back to returning an empty string if the
    # tool is unavailable.
    class TextExtractor
      attr_reader :path

      def initialize(path)
        @path = path.to_s
      end

      # Returns an Array of Strings — one per page. Uses +pdftotext+
      # in raw mode (no layout reconstruction) for maximum text
      # recovery. For layout-aware extraction, pass +layout: true+.
      def pages(layout: false)
        return [] unless pdftotext_available?

        args = ['pdftotext']
        args << '-layout' if layout
        args << '-q' << @path << '-'
        stdout, _stderr, status = Open3.capture3(*args)
        return [] unless status.success?

        text = stdout.force_encoding('UTF-8').scrub
        split_by_page(text)
      end

      # Returns all text as a single String (pages joined by "\f").
      def full_text(layout: false)
        pages(layout: layout).join("\f")
      end

      # Word count across all pages.
      def word_count
        pages.sum { |text| text.split.length }
      end

      private

      def pdftotext_available?
        _, _, status = Open3.capture3('which', 'pdftotext')
        status.success?
      end

      def split_by_page(text)
        return [text] unless text.include?("\f")

        text.split("\f", -1)
      end
    end
  end
end
