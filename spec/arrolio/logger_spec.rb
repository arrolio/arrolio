# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe Arrolio::Logger do
  before { described_class.reset! }

  describe '.level and .level_name' do
    it 'defaults to :warn' do
      expect(described_class.level_name).to eq(:warn)
    end

    it 'accepts :debug' do
      described_class.level = :debug
      expect(described_class.level_name).to eq(:debug)
    end

    it 'falls back to default for unknown levels' do
      described_class.level = :bogus
      expect(described_class.level_name).to eq(:warn)
    end
  end

  describe '.debug / .info / .warn / .error' do
    let(:sink) { StringIO.new }

    before { described_class.target = sink }

    it 'suppresses debug at :warn level' do
      described_class.level = :warn
      described_class.debug('invisible')
      expect(sink.string).to eq('')
    end

    it 'emits debug at :debug level' do
      described_class.level = :debug
      described_class.debug('visible')
      expect(sink.string).to include('[debug] visible')
    end

    it 'emits warn at :warn level' do
      described_class.level = :warn
      described_class.warn('problem')
      expect(sink.string).to include('[warn] problem')
    end

    it 'emits error at :warn level' do
      described_class.warn('broken')
      expect(sink.string).to include('[warn] broken')
    end

    it 'suppresses info at :warn level but emits at :info' do
      described_class.level = :warn
      described_class.info('nope')
      expect(sink.string).to eq('')

      described_class.level = :info
      described_class.info('now')
      expect(sink.string).to include('[info] now')
    end
  end

  describe '.reset!' do
    it 'restores defaults' do
      described_class.level = :debug
      described_class.reset!
      expect(described_class.level_name).to eq(:warn)
    end
  end
end
