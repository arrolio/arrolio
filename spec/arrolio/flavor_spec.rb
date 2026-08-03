# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arrolio::Flavor::Registry do
  after { described_class.reset! }

  describe '.register and .for' do
    it 'registers and retrieves a flavor pipeline' do
      pipeline = Class.new do
        def self.render(_xml, io:, **_opts); end
      end
      described_class.register(:test_flavor, pipeline)
      expect(described_class.for(:test_flavor)).to eq(pipeline)
    end

    it 'raises for unknown flavor' do
      expect { described_class.for(:nonexistent) }.to raise_error(ArgumentError)
    end
  end

  describe '.registered?' do
    it 'returns true for registered flavors' do
      described_class.register(:x, Class.new)
      expect(described_class).to be_registered(:x)
    end

    it 'returns false for unregistered flavors' do
      expect(described_class).not_to be_registered(:y)
    end
  end

  describe '.names' do
    it 'lists all registered flavor names' do
      described_class.register(:a, Class.new)
      described_class.register(:b, Class.new)
      expect(described_class.names).to contain_exactly(:a, :b)
    end
  end

  describe '.reset!' do
    it 'clears all registrations' do
      described_class.register(:x, Class.new)
      described_class.reset!
      expect(described_class.names).to be_empty
    end
  end
end

RSpec.describe Arrolio::Flavor do
  it 'autoloads Registry' do
    expect(described_class::Registry).to be_a(Class)
  end
end

RSpec.describe 'OCP: Arrolio gem is flavor-agnostic' do
  let(:gem_root) { File.expand_path('../..', __dir__) }

  it 'does not autoload any flavor module from core' do
    core = File.read(File.join(gem_root, 'lib/arrolio.rb'))
    expect(core).not_to include('autoload :Oiml')
    expect(core).not_to match(/autoload :Oiml\b/)
  end

  it 'autoloads Flavor from core' do
    core = File.read(File.join(gem_root, 'lib/arrolio.rb'))
    expect(core).to include('autoload :Flavor')
  end

  it 'does not have OIML_LOGO_PATHS in the renderer' do
    renderer = File.read(File.join(gem_root, 'lib/arrolio/renderer/pdf.rb'))
    expect(renderer).not_to include('OIML_LOGO_PATHS')
  end

  it 'ships no flavor-specific Ruby under lib/' do
    lib_files = Dir.glob(File.join(gem_root, 'lib/**/*.rb'))
    flavor_specific = lib_files.grep(%r{/(oiml|iso|iec|bsi)\b}i)
    expect(flavor_specific).to be_empty
  end

  it 'ships no flavor-specific data packaged by the gemspec' do
    gemspec_path = File.join(gem_root, 'arrolio.gemspec')
    gemspec = File.read(gemspec_path)
    expect(gemspec).to include('flavors/')

    packaged = Dir.chdir(gem_root) do
      `git ls-files -z`.split("\x0").reject do |f|
        f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) ||
          f.start_with?('flavors/')
      end
    end
    flavor_files = packaged.grep(%r{\Aflavors/})
    expect(flavor_files).to be_empty
  end
end
