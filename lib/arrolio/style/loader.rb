# frozen_string_literal: true

require 'yaml'

module Arrolio
  module Style
    module Loader
      module_function

      def load(source)
        Registry.new(load_hash(source) || {})
      end

      def load_hash(source)
        case source
        when Hash then source
        when String then ::YAML.safe_load(source, aliases: true) || {}
        when IO, StringIO then ::YAML.safe_load(source.read, aliases: true) || {}
        else
          raise ArgumentError, 'Loader.load needs a Hash, String, or IO'
        end
      end
    end
  end
end
