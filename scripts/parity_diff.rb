#!/usr/bin/env ruby
# frozen_string_literal: true

# Parity diff diagnostics: shows per-page text differences between
# our rendered PDF and the reference PDF.
#
# Usage:
#   bundle exec ruby scripts/parity_diff.rb              # all pages
#   bundle exec ruby scripts/parity_diff.rb 5             # page 5 only
#   bundle exec ruby scripts/parity_diff.rb 19 20 21      # pages 19-21

require 'arrolio'
require 'fileutils'

module ParityDiff
  OURS = File.expand_path('tmp/parity_check.pdf', Dir.pwd)
  REFERENCE = File.expand_path('~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.pdf')
  FIXTURE = File.expand_path('~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.presentation.xml')
  SOURCE_DIR = File.expand_path('~/src/mn/mn-samples-oiml/sources/r060/1')
  FLAVOR_DIR = File.expand_path('flavors/oiml', Dir.pwd)

  def self.run(pages = nil)
    render_ours unless File.exist?(OURS)
    unless File.exist?(OURS) && File.exist?(REFERENCE)
      warn 'PDFs not found. Run parity:check first.'
      return
    end

    ours_pages = page_count(OURS)
    ref_pages = page_count(REFERENCE)
    target_pages = pages&.map(&:to_i) || (1..[ours_pages, ref_pages].max).to_a

    target_pages.each do |page_num|
      puts '=' * 70
      puts "PAGE #{page_num}"
      puts '=' * 70
      ours_text = extract_text(OURS, page_num)
      ref_text = extract_text(REFERENCE, page_num)
      show_diff(ours_text, ref_text)
      puts ''
    end
  end

  def self.render_ours
    require 'arrolio/config_driven_pipeline'
    xml = File.read(FIXTURE)
    FileUtils.mkdir_p(File.dirname(OURS))
    Arroolio::ConfigDrivenPipeline.render(
      xml, io: OURS, flavor_dir: FLAVOR_DIR,
           input_path: FIXTURE, extra_image_dirs: [SOURCE_DIR]
    )
  end

  def self.page_count(pdf)
    `pdftotext "#{pdf}" - 2>/dev/null`.scan("\f").length + 1
  rescue StandardError
    0
  end

  def self.extract_text(pdf, page)
    `pdftotext -f #{page} -l #{page} "#{pdf}" - 2>/dev/null`
      .delete("\f").strip
  end

  def self.show_diff(ours, ref)
    our_lines = ours.split("\n")
    ref_lines = ref.split("\n")
    max_lines = [our_lines.length, ref_lines.length].max

    max_lines.times do |i|
      our_line = our_lines[i] || ''
      ref_line = ref_lines[i] || ''

      if our_line == ref_line
        puts "  #{our_line}"
      elsif our_line.empty?
        puts "+ #{ref_line}"  # missing from ours
      elsif ref_line.empty?
        puts "- #{our_line}"  # extra in ours
      else
        puts "~ OURS:  #{our_line}"
        puts "  REF:   #{ref_line}"
      end
    end
  end
end

pages = ARGV.empty? ? nil : ARGV
ParityDiff.run(pages)
