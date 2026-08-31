# frozen_string literal: true
# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Arrolio::AssetResolver do
  it 'passes through absolute paths and URLs' do
    resolver = described_class.new(base_dirs: [])
    expect(resolver.resolve('/abs/img.png')).to eq('/abs/img.png')
    expect(resolver.resolve('https://example.com/a.png')).to eq('https://example.com/a.png')
    expect(resolver.resolve(nil)).to be_nil
    expect(resolver.resolve('')).to eq('')
  end

  it 'resolves a relative source against the first base dir that has it' do
    Dir.mktmpdir do |dir_a|
      Dir.mktmpdir do |dir_b|
        File.write(File.join(dir_b, 'fig.png'), 'x')
        resolver = described_class.new(base_dirs: [dir_a, dir_b])
        expect(resolver.resolve('fig.png')).to eq(File.join(dir_b, 'fig.png'))
      end
    end
  end

  it 'falls back to the source when no base dir has it' do
    resolver = described_class.new(base_dirs: [])
    expect(resolver.resolve('missing.png')).to eq('missing.png')
  end

  it 'derives base dirs from the input path plus extras' do
    resolver = described_class.from_input_path('/work/doc/input.xml',
                                               extra: ['/assets'])
    expect(resolver.base_dirs).to eq(['/work/doc', '/assets'])
    expect(resolver).to be_frozen
  end

  it 'skips the input dir when the input path is nil' do
    resolver = described_class.from_input_path(nil, extra: ['/assets'])
    expect(resolver.base_dirs).to eq(['/assets'])
  end
end
