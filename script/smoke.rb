#!/usr/bin/env ruby
# frozen_string_literal: true

# Smoke test for Arrolio. Run: bundle exec ruby -Ilib script/smoke.rb
#
# Style is a MODULE (with Definition/Registry/Loader autoloads) in this
# codebase — not a class. Adjust accordingly.

require 'arrolio'

puts "VERSION: #{Arrolio::VERSION}"

# Font metrics — direct API
m = Arrolio::GlyphMeasurer.new(font_name: 'Helvetica')
puts "GlyphMeasurer 'Hello' at 12pt: #{m.width_of_string('Hello', font_size: 12)}"

# Inline run + Frame
puts "InlineRun: #{Arrolio::InlineRun.new('hi').text}"
frame = Arrolio::Frame.new(x: 0, y: 0, width: 100, height: 200)
puts "Frame remaining_height: #{frame.remaining_height}"

# Content::Document
doc = Arrolio::Content::Document.build { |b| b.paragraph('Hello, World!') }
puts "Content::Document sections: #{doc.sections.length}"

# LayoutSpec
spec = Arrolio::LayoutSpec.build do |s|
  s.page_template(:body)
end
puts "LayoutSpec page_template(:body): #{spec.page_template(:body).class}"

puts 'OK'
