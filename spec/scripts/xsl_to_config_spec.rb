# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'

RSpec.describe 'scripts/xsl_to_config.rb' do
  let(:xsl_path) { File.expand_path('~/src/mn/metanorma-taste/data/oiml/oiml.xsl') }
  let(:script_path) { File.expand_path('../../scripts/xsl_to_config.rb', __dir__) }

  before { skip 'oiml.xsl not present' unless File.exist?(xsl_path) }

  it 'regenerates the three OIML YAML files from the stylesheet' do
    Dir.mktmpdir do |dir|
      output = system('bundle', 'exec', 'ruby', script_path, xsl_path, dir, err: File::NULL)
      raise 'xsl_to_config.rb failed' unless output

      layout = YAML.safe_load_file(File.join(dir, 'layout_spec.yml'), aliases: true)
      adapter = YAML.safe_load_file(File.join(dir, 'adapter_rules.yml'), aliases: true)
      flow = YAML.safe_load_file(File.join(dir, 'flow_rules.yml'), aliases: true)

      expect(layout['stylesheet']).to eq('oiml.xsl')
      expect(layout['xsl_variables']).to include('marginTop' => '26.5')
      expect(adapter['element_mapping']).to include('clause')
      expect(flow['page_sequences'].first['role']).to eq('cover')
    end
  end
end
