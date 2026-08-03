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
