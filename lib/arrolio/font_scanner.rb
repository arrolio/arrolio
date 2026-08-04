# frozen_string_literal: true

require 'fontisan'

module Arrolio
  # Scans font directories for TTF files and builds an index of
  # family-name → file-path mappings using Fontisan to read each
  # font's internal name tables. Used by ConfigDrivenPipeline to
  # resolve font family names referenced by layout styles to actual
  # TTF files on disk.
  class FontScanner
    FONT_DIRECTORIES = [
      File.expand_path('~/.fontist/fonts'),
      '/Library/Fonts',
      '/System/Library/Fonts',
      File.expand_path('~/Library/Fonts')
    ].freeze

    attr_reader :index

    def initialize(directories = FONT_DIRECTORIES)
      @directories = directories
      @index = nil
    end

    def resolve(font_name)
      build_index unless @index
      @index[font_name.to_s]
    end

    def build_index
      @index = {}
      @directories.each do |dir|
        scan_directory(dir)
      end
      @index
    end

    private

    def scan_directory(dir)
      Dir.glob(File.join(dir, '**', '*.ttf')).each do |path|
        add_to_index(path)
      end
      Dir.glob(File.join(dir, '**', '*.TTF')).each do |path|
        add_to_index(path)
      end
    end

    def add_to_index(path)
      info = read_font_info(path)
      return unless info

      info[:names].each do |name|
        @index[name] ||= path
      end
    end

    def read_font_info(path)
      font = Fontisan::FontLoader.load(path)
      name_table = font.table('name')
      return nil unless name_table

      storage = name_table.string_storage
      names = extract_names(name_table, storage)
      weight = extract_weight(font)

      names.map { |n| @index[n] ||= path }

      # Also register family + variant combos
      family = names.find { |n| n == name_id(name_table, storage, 1) }
      return nil unless family

      { names: names, family: family, weight: weight }
    rescue StandardError
      nil
    end

    def extract_names(name_table, storage)
      names = []
      [1, 4, 6, 16].each do |name_id|
        name = name_id(name_table, storage, name_id)
        names << name if name && !name.empty?
      end
      # Register family + variant suffix for bold/italic resolution
      family = name_id(name_table, storage, 1)
      subfamily = name_id(name_table, storage, 2)
      if family && subfamily
        names << "#{family} #{subfamily}" unless subfamily == 'Regular'
        names << family if subfamily == 'Regular'
      end
      names.uniq
    end

    def extract_weight(font)
      os2 = font.table('OS/2')
      return nil unless os2

      os2.weight_class rescue nil
    end

    def name_id(name_table, storage, id)
      record = name_table.name_records.find do |r|
        r.name_id == id && r.platform_id == 3
      end
      return nil unless record

      storage.byteslice(record.string_offset, record.string_length)
             .force_encoding('UTF-16BE')
             .encode('UTF-8', invalid: :replace, undef: :replace)
             .strip
    rescue StandardError
      nil
    end
  end
end
