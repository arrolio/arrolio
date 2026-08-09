# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: [:spec, :rubocop]

namespace :flavor do
  GENERATOR = File.expand_path('scripts/xsl_to_config.rb', __dir__)

  desc 'Regenerate flavor config from an XSL stylesheet (XSL=, OUT=)'
  task :generate do
    xsl = ENV.fetch('XSL') { raise 'Set XSL= to the stylesheet path' }
    out = ENV.fetch('OUT') { raise 'Set OUT= to the flavor directory' }
    sh "bundle exec ruby #{GENERATOR} #{File.expand_path(xsl)} #{File.expand_path(out)}"
  end
end

namespace :parity do
  desc 'Render the OIML r060/1 fixture and diff against the reference PDF'
  task :check do
    sh 'bundle exec ruby -Ilib scripts/parity_check.rb'
  end

  desc 'Show per-page text diff (PAGE=5 or PAGE=5,6,7)'
  task :diff do
    pages = ENV['PAGE']&.split(',')&.map(&:strip)
    cmd = 'bundle exec ruby -Ilib scripts/parity_diff.rb'
    cmd += " #{pages.join(' ')}" if pages&.any?
    sh cmd
  end
end
