# frozen_string_literal: true

module Arrolio
  class AssetResolver
    attr_reader :base_dirs

    def initialize(base_dirs:)
      @base_dirs = Array(base_dirs).map { |directory| File.expand_path(directory.to_s) }.freeze
      freeze
    end

    def resolve(source)
      return source if source.nil? || source.empty?
      return source if absolute?(source)

      @base_dirs.each do |base_dir|
        candidate = File.join(base_dir, source)
        return candidate if File.exist?(candidate)
      end
      source
    end

    def self.from_input_path(input_path, extra: [])
      directories = []
      directories << File.dirname(File.expand_path(input_path)) if input_path
      directories.concat(Array(extra))
      new(base_dirs: directories)
    end

    private

    def absolute?(source)
      source.start_with?('/', 'http://', 'https://')
    end
  end
end
