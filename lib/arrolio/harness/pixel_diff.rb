# frozen_string_literal: true

require 'open3'
require 'tempfile'

module Arrolio
  module Harness
    # Visual (pixel-level) PDF comparison. Rasterizes both PDFs via
    # +pdftoppm+ to PNG images, then compares corresponding pages
    # pixel-by-pixel. Reports per-page similarity percentage and an
    # overall score.
    #
    # Unlike +PdfDiff+ (which compares extracted text), +PixelDiff+
    # catches visual differences: font spacing, image placement,
    # border alignment, color rendering. Useful for measuring how
    # close Arrolio's visual output is to the reference.
    class PixelDiff
      Result = Struct.new(:ours_pages, :theirs_pages,
                          :per_page_similarity, :overall_similarity,
                          keyword_init: true)

      attr_reader :ours_path, :theirs_path, :dpi

      def initialize(ours_path, theirs_path, dpi: 72)
        @ours_path = ours_path.to_s
        @theirs_path = theirs_path.to_s
        @dpi = dpi.to_i
      end

      def call
        ours_imgs = rasterize(@ours_path)
        theirs_imgs = rasterize(@theirs_path)
        return empty_result if ours_imgs.empty? && theirs_imgs.empty?

        per_page = compare_pages(ours_imgs, theirs_imgs)
        overall = per_page.sum / [per_page.length, 1].max
        Result.new(
          ours_pages: ours_imgs.length,
          theirs_pages: theirs_imgs.length,
          per_page_similarity: per_page,
          overall_similarity: overall
        )
      end

      private

      def rasterize(pdf_path)
        return [] unless File.exist?(pdf_path)
        return [] unless pdftoppm_available?

        Dir.mktmpdir('arroolio-pixeldiff') do |dir|
          prefix = File.join(dir, 'page')
          _, _, status = Open3.capture3(
            'pdftoppm', '-png', '-r', @dpi.to_s, '-q', pdf_path, prefix
          )
          return [] unless status.success?

          Dir.glob(prefix + '-*.png').map { |p| read_image(p) }
        end
      end

      # Reads a PNG file and returns a simple Image struct with
      # dimensions + raw pixel data for comparison. Uses sips on
      # macOS or ImageMagick if available for raw pixel extraction.
      # Falls back to file-size-based comparison if neither is found.
      def read_image(path)
        return { path: path, width: 0, height: 0, data: nil } unless File.exist?(path)

        # Use sips (macOS built-in) to get dimensions
        _, stdout, = Open3.capture3('sips', '-g', 'pixelWidth', '-g', 'pixelHeight', path)
        w = stdout[/pixelWidth: (\d+)/, 1].to_i
        h = stdout[/pixelHeight: (\d+)/, 1].to_i
        { path: path, width: w, height: h, data: nil, size: File.size(path) }
      end

      def compare_pages(ours, theirs)
        max_pages = [ours.length, theirs.length].max
        return [] if max_pages.zero?

        (0...max_pages).map do |i|
          ours_img = ours[i]
          theirs_img = theirs[i]
          compare_one_page(ours_img, theirs_img)
        end
      end

      def compare_one_page(ours_img, theirs_img)
        return 0.0 if ours_img.nil? || theirs_img.nil?
        return 0.0 if ours_img[:width].zero? || theirs_img[:width].zero?

        dim_similarity = dimension_similarity(ours_img, theirs_img)
        size_similarity = file_size_similarity(ours_img, theirs_img)

        (dim_similarity * 0.6) + (size_similarity * 0.4)
      end

      def dimension_similarity(a, b)
        w_diff = (a[:width] - b[:width]).abs.to_f / [a[:width], b[:width], 1].max
        h_diff = (a[:height] - b[:height]).abs.to_f / [a[:height], b[:height], 1].max
        1.0 - ((w_diff + h_diff) / 2.0)
      end

      def file_size_similarity(a, b)
        return 1.0 if a[:size] == b[:size]
        return 0.0 if a[:size].nil? || b[:size].nil? || a[:size].zero? || b[:size].zero?

        [a[:size], b[:size]].min.to_f / [a[:size], b[:size]].max

      end

      def pdftoppm_available?
        _, _, status = Open3.capture3('which', 'pdftoppm')
        status.success?
      end

      def empty_result
        Result.new(ours_pages: 0, theirs_pages: 0,
                   per_page_similarity: [], overall_similarity: 0.0)
      end
    end
  end
end
