# frozen_string_literal: true

module Arrolio
  module DataDir
    DELIMITER = '/'

    class << self
      def root
        File.expand_path('../../data/arrolio', __dir__)
      end

      def resolve(*segments)
        path = File.join(root, *segments)
        raise Arrolio::Error, "missing data file: #{segments.join(DELIMITER)}" unless File.exist?(path)

        path
      end

      def afm(name)
        File.join(root, 'afm', "#{name}.afm")
      end

      def glyphlist
        File.join(root, 'glyphlist.txt')
      end
    end
  end
end
