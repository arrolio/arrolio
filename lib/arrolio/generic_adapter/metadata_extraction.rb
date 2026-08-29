# frozen_string_literal: true

module Arrolio
  class GenericAdapter
    # Extracted conversion seam (TODO 56): one module per concern,
    # included into the adapter. The class keeps dispatch and glue.
    module MetadataExtraction
      def extract_metadata(root)
        config = @rules['metadata'] || {}
        bibdata_path = config['root'] || 'bibdata'
        bibdata = find_first(root, bibdata_path)
        return {} unless bibdata

        result = {}
        (config['fields'] || {}).each do |key, xpath|
          value = text_of(find_first(bibdata, xpath))
          result[key.to_sym] = value if value && !value.empty?
        end
        derive_metadata_fields(result)
        result
      end

      def derive_metadata_fields(result)
        lang = result[:language].to_s
        version_date = result[:revision_date]
        year = version_date&.[](0, 4)
        result[:revision_year] = year if year&.match?(/\A\d{4}\z/)
        return if lang.empty? && version_date.nil?

        lang_initial = lang[0, 1].upcase
        year_part = year&.match?(/\A\d{4}\z/) ? "#{year} " : ''
        result[:edition_label] = "#{year_part}(#{lang_initial})"
      end

      def extract_cover(root)
        metadata = extract_metadata(root)
        config = @rules['cover'] || {}
        result = {}
        (config['fields'] || ['docidentifier', 'edition', 'title_main', 'title_part']).each do |field|
          result[field.to_sym] = metadata[field.to_sym] if metadata[field.to_sym]
        end
        result.empty? ? nil : result
      end
    end
  end
end
