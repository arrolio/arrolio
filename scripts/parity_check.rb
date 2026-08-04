# frozen_string_literal: true

require 'arrolio'
require 'fileutils'

module ParityCheck
  REFERENCE = File.expand_path('~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.pdf')
  FIXTURE = File.expand_path('~/src/mn/mn-samples-oiml/_site/documents/r060/1/document.presentation.xml')
  FLAVOR_DIR = File.expand_path('../flavors/oiml', __dir__)
  OUTPUT = File.expand_path('../tmp/parity_check.pdf', __dir__)

  def self.run
    unless File.exist?(REFERENCE) && File.exist?(FIXTURE)
      warn 'OIML fixture or reference PDF not found. Skipping parity check.'
      warn "  Reference: #{REFERENCE}" unless File.exist?(REFERENCE)
      warn "  Fixture:   #{FIXTURE}" unless File.exist?(FIXTURE)
      return
    end

    FileUtils.mkdir_p(File.dirname(OUTPUT))
    xml = File.read(FIXTURE)
    Arrolio::ConfigDrivenPipeline.render(xml, io: OUTPUT, flavor_dir: FLAVOR_DIR, input_path: FIXTURE)

    require 'arrolio/harness'
    diff = Arrolio::Harness::PdfDiff.new(OUTPUT, REFERENCE)
    result = diff.call

    puts "Overall similarity: #{result.overall_similarity.round(2)}%"
    puts "Our pages: #{result.ours_pages}, Reference pages: #{result.theirs_pages}"
    puts ''
    result.per_page.each do |page|
      status = if page.similarity > 50 then 'OK'
               elsif page.similarity > 10 then 'PARTIAL'
               else 'LOW'
               end
      puts "  Page #{page.number}: #{page.similarity.round(1)}% [#{status}]"
    end
    puts ''
    puts 'Target: > 50% overall similarity'
    result.overall_similarity
  end
end
