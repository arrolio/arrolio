# frozen_string_literal: true

module Arrolio
  module Renderer
    # Configuration for PDF digital signatures. Carries the keystore
    # path, password, and certification level. The renderer applies
    # the signature as a post-processing step using an external
    # signing tool (or a future Pdfrb signing API).
    #
    # Certification levels (PDF 1.7 §12.8.2.2):
    # +:no_changes+ — no changes permitted after signing.
    # +:form_fill+ — form filling and signing permitted.
    # +:annotate+ — annotations + form fill + signing permitted.
    class SignatureConfig
      CERT_LEVELS = {
        no_changes: 1,
        form_fill: 2,
        annotate: 3
      }.freeze

      attr_reader :keystore_path, :keystore_password, :cert_level,
                  :reason, :location, :name

      def initialize(keystore_path:, keystore_password:,
                     cert_level: :form_fill, reason: nil, location: nil,
                     name: nil)
        @keystore_path = keystore_path.to_s
        @keystore_password = keystore_password.to_s
        @cert_level = cert_level.to_sym
        @reason = reason&.to_s
        @location = location&.to_s
        @name = name&.to_s
        freeze
      end

      def cert_level_code
        CERT_LEVELS.fetch(@cert_level, 2)
      end

      def valid?
        !@keystore_path.empty? && !@keystore_password.empty?
      end

      def ==(other)
        other.is_a?(self.class) &&
          keystore_path == other.keystore_path &&
          cert_level == other.cert_level &&
          reason == other.reason &&
          location == other.location &&
          name == other.name
      end
      alias eql? ==

      def hash
        [self.class, keystore_path, cert_level, reason, location, name].hash
      end
    end
  end
end
