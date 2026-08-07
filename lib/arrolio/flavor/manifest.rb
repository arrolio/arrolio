# frozen_string_literal: true

require 'yaml'

module Arrolio
  module Flavor
    # Typed view over a flavor's manifest.yml. Declares the flavor's
    # name, version, upstream XSL, required/optional fonts, and the
    # paths to its three config files. Validates the manifest at load
    # time so broken flavors fail loudly with `Arrolio::FlavorError`.
    class Manifest
      REQUIRED_FIELDS = ['name', 'version', 'config_files'].freeze

      attr_reader :path, :name, :version, :description, :upstream,
                  :doctypes, :required_fonts, :optional_fonts,
                  :config_files

      def self.load(flavor_dir)
        manifest_path = File.join(flavor_dir, 'manifest.yml')
        unless File.exist?(manifest_path)
          raise ::Arrolio::FlavorError.new(
            "manifest.yml not found in #{flavor_dir}",
            flavor_dir: flavor_dir
          )
        end

        data = YAML.safe_load_file(manifest_path, aliases: true)
        unless data.is_a?(Hash)
          raise ::Arrolio::FlavorError.new(
            "manifest.yml at #{manifest_path} is not a YAML mapping",
            flavor_dir: flavor_dir
          )
        end

        validate_required_fields!(data, manifest_path)
        validate_config_files!(data, manifest_path, flavor_dir)

        new(manifest_path, data)
      end

      def initialize(path, data)
        @path = path
        @name = data.fetch('name')
        @version = data.fetch('version')
        @description = data['description']
        @upstream = data['upstream'] || {}
        @doctypes = data['doctypes'] || []
        fonts = data['fonts'] || {}
        @required_fonts = fonts['required'] || []
        @optional_fonts = fonts['optional'] || []
        @config_files = data.fetch('config_files')
        freeze
      end

      def config_path_for(role, flavor_dir = File.dirname(@path))
        file = config_files[role.to_s] || config_files[role.to_sym]
        return nil unless file

        File.join(flavor_dir, file)
      end

      def ==(other)
        other.is_a?(self.class) &&
          path == other.path &&
          name == other.name &&
          version == other.version &&
          description == other.description &&
          doctypes == other.doctypes &&
          required_fonts == other.required_fonts &&
          optional_fonts == other.optional_fonts &&
          config_files == other.config_files
      end

      alias eql? ==

      def hash
        [self.class, path, name, version, config_files].hash
      end

      def self.validate_required_fields!(data, manifest_path)
        missing = REQUIRED_FIELDS.reject { |field| data.key?(field) }
        return if missing.empty?

        raise ::Arrolio::FlavorError.new(
          "manifest at #{manifest_path} is missing required fields: #{missing.inspect}",
          manifest_path: manifest_path, missing_fields: missing
        )
      end
      private_class_method :validate_required_fields!

      def self.validate_config_files!(data, manifest_path, flavor_dir)
        config_files = data['config_files']
        return unless config_files.is_a?(Hash)

        ['layout_spec', 'adapter_rules', 'flow_rules'].each do |role|
          filename = config_files[role]
          next unless filename
          next if File.exist?(File.join(flavor_dir, filename))

          raise ::Arrolio::FlavorError.new(
            "manifest at #{manifest_path} references #{role}=#{filename}, " \
            'but the file does not exist',
            manifest_path: manifest_path, missing_role: role
          )
        end
      end
      private_class_method :validate_config_files!
    end
  end
end
