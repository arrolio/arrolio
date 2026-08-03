# frozen_string_literal: true

module Arrolio
  module FontMetrics
    module Registry
      @cache = {}
      @ttf_paths = {}

      class << self
        attr_reader :ttf_paths

        def register_ttf(font_name, path)
          @ttf_paths[font_name.to_s] = path
          @cache.delete(font_name.to_s)
        end

        def register_ttf_all(paths, strict: false)
          missing = []
          paths.each do |name, path|
            register_ttf(name, path)
            missing << [name, path] if strict && path && File.exist?(path) == false
          end
          return unless strict && missing.any?

          raise Arrolio::RenderError.new(
            'strict mode: missing required font files: ' +
              missing.map { |name, path| "#{name}=#{path}" }.join(', '),
            missing_fonts: missing
          )
        end

        def [](font_name)
          key = font_name.to_s
          return @cache[key] if @cache.key?(key)

          if @ttf_paths.key?(key) && File.exist?(@ttf_paths[key])
            @cache[key] = TrueTypeMetrics.from_file(key, @ttf_paths[key])
            return @cache[key]
          end

          @cache[key] = AfmMetrics.for_name(key)
        end

        def reset!
          @cache.clear
          @ttf_paths.clear
        end

        def known?(font_name)
          !self[font_name].nil?
        end
      end
    end
  end
end
