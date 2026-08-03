# frozen_string_literal: true

module Arrolio
  # Structured logging facade. Replaces scattered +warn+ calls with
  # level-filtered, silencable output. Default level +:warn+ keeps
  # production rendering quiet; set +Arrolio::Logger.level = :debug+
  # or +ARROOLIO_LOG_LEVEL=debug+ to restore tracing during development.
  class Logger
    LEVELS = { debug: 0, info: 1, warn: 2, error: 3 }.freeze
    DEFAULT_LEVEL = :warn

    @level = LEVELS.fetch(DEFAULT_LEVEL)
    @target = $stderr

    class << self
      attr_accessor :target
      attr_reader :level

      def level=(name)
        @level = LEVELS.fetch(name.to_sym) { LEVELS.fetch(DEFAULT_LEVEL) }
      end

      def level_name
        LEVELS.key(@level) || DEFAULT_LEVEL
      end

      LEVELS.each_key do |name|
        define_method(name) do |msg|
          emit(name, msg)
        end
      end

      # Reset to defaults — used by specs and between pipeline runs.
      def reset!
        @level = LEVELS.fetch(DEFAULT_LEVEL)
        @target = $stderr
      end

      private

      def emit(level_name, msg)
        threshold = LEVELS.fetch(level_name)
        return if threshold < @level

        @target.puts "[#{level_name}] #{msg}"
      end
    end

    # Pick up the env var on first load. Allows
    # +ARROOLIO_LOG_LEVEL=debug bundle exec rake+ without code changes.
    env_level = ENV['ARROOLIO_LOG_LEVEL'].to_s.strip
    self.level = env_level unless env_level.empty?
  end
end
