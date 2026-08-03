#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'yaml'

module XslConfigGenerator
  XSL_NS = 'http://www.w3.org/1999/XSL/Transform'
  FO_NS = 'http://www.w3.org/1999/XSL/Format'
  DEFAULT_PROFILE = File.expand_path('xsl_profiles/standoc.yml', __dir__).freeze

  def self.generate(xsl_path:, output_dir:, profile: DEFAULT_PROFILE)
    Builder.new(xsl_path, output_dir, profile).generate
  end

  class Builder
    def initialize(xsl_path, output_dir, profile_path)
      @xsl_path = File.expand_path(xsl_path)
      @output_dir = File.expand_path(output_dir)
      @profile_path = profile_path
      @stylesheet = File.basename(@xsl_path)
      @profile = YAML.safe_load_file(profile_path, aliases: true) || {}
      @document = Nokogiri::XML(File.read(@xsl_path)) { |config| config.nonet }
      @attribute_sets = extract_attribute_sets
      @variables = extract_variables
      @templates = extract_templates
    end

    def generate
      File.write(File.join(@output_dir, 'layout_spec.yml'), yaml_file(layout_spec))
      File.write(File.join(@output_dir, 'adapter_rules.yml'), yaml_file(adapter_rules))
      File.write(File.join(@output_dir, 'flow_rules.yml'), yaml_file(flow_rules))
      profile_name = File.basename(@profile_path)
      warn "generated XSL configuration from #{@stylesheet} (profile: #{profile_name}) in #{@output_dir}"
    end

    private

    def stylesheet_name
      @stylesheet
    end

    def layout_spec
      {
        'generated_from' => stylesheet_name,
        'profile' => File.basename(@profile_path),
        'stylesheet' => stylesheet_name,
        'xsl_variables' => @variables,
        'xsl_attribute_sets' => @attribute_sets,
        'default_page_template' => 'body',
        'page_templates' => {
          'body' => {
            'page_size' => 'A4',
            'margins' => {
              'top' => length(@variables['marginTop'], '26.5mm'),
              'bottom' => length(@variables['marginBottom'], '26.5mm'),
              'left' => length(@variables['marginLeftRight1'], '25.5mm'),
              'right' => length(@variables['marginLeftRight1'], '25.5mm')
            },
            'region_extents' => { 'before' => '18mm', 'after' => '18mm' }
          }
        },
        'styles' => styles,
        'flows' => {
          'main' => { 'region' => 'body', 'default_style_id' => 'body' }
        }
      }
    end

    def styles
      text_styles.merge(inline_styles_arg)
                 .merge(list_styles)
                 .merge(table_styles)
                 .merge(structure_styles)
    end

    def text_styles
      o = @profile['style_overrides'] || {}
      {
        'body' => style_from('root-style', 'clause_style').merge('margin_bottom' => o['body_margin_bottom'] || 8),
        **heading_styles,
        'note' => style_from('note-style').merge('parent' => 'body'),
        'termnote' => style_from('termnote-style').merge('parent' => 'body'),
        'note_label' => style_from('note-name-style').merge(
          'parent' => 'body', 'font_name' => o['em_font_name']
        ),
        'example' => style_from('example-style').merge('parent' => 'body'),
        'caption_label' => { 'parent' => 'body' },
        'example_label' => { 'parent' => 'note_label' }
      }
    end

    def inline_styles_arg
      o = @profile['style_overrides'] || {}
      {
        'inline' => { 'parent' => 'body' },
        'strong' => { 'parent' => 'body', 'font_name' => o['strong_font_name'] },
        'em' => { 'parent' => 'body', 'font_name' => o['em_font_name'] },
        'monospace' => { 'parent' => 'body', 'font_name' => 'Courier' },
        'preformatted' => {
          'parent' => 'body', 'font_name' => 'Courier', 'font_size' => 9,
          'align' => 'left', 'line_spacing' => 1.0, 'margin_bottom' => 6
        },
        'identifier' => { 'parent' => 'body', 'font_name' => o['identifier_font_name'] },
        'term' => style_from('term-style').merge('parent' => 'body', 'font_name' => o['term_font_name']),
        'xref' => style_from('xref-style').merge('parent' => 'body'),
        'link' => style_from('link-style').merge('parent' => 'body', 'font_name' => o['link_font_name']),
        'bibitem' => { 'parent' => 'body', 'margin_top' => 4, 'margin_bottom' => 4 },
        'footnote' => { 'parent' => 'body', 'font_size' => 9, 'margin_top' => 2, 'margin_bottom' => 2 }
      }
    end

    def table_styles
      o = @profile['style_overrides'] || {}
      {
        'table' => { 'parent' => 'body', 'font_size' => 10 },
        'table_cell' => { 'parent' => 'table', 'margin_top' => 2, 'margin_bottom' => 2 },
        'table_header_cell' => { 'parent' => 'table_cell', 'font_name' => o['table_header_cell_font_name'] },
        'figure_caption' => style_from('figure-name-style').merge(
          'parent' => 'body', 'font_size' => 10, 'align' => 'center'
        )
      }
    end

    def structure_styles
      toc_styles.merge(cover_styles).merge(section_styles)
    end

    def toc_styles
      {
        'toc_title' => style_from('toc-title-style').merge('parent' => 'body'),
        'toc_entry' => { 'parent' => 'body', 'font_size' => 11 },
        'toc_entry_sub' => { 'parent' => 'toc_entry', 'margin_left' => 12 }
      }
    end

    def cover_styles
      o = @profile['style_overrides'] || {}
      {
        'cover_docidentifier' => {
          'parent' => 'body', 'font_name' => o['cover_docidentifier_font_name'], 'font_size' => 28,
          'align' => 'center', 'fill_color' => '#221E1F'
        },
        'cover_title' => {
          'parent' => 'body', 'font_name' => o['cover_title_font_name'], 'font_size' => 16, 'align' => 'center'
        },
        'cover_title_part' => { 'parent' => 'cover_title', 'font_size' => 14 },
        'cover_title_other' => {
          'parent' => 'body', 'font_name' => o['cover_title_other_font_name'], 'font_size' => 11, 'align' => 'center'
        },
        'cover_org' => { 'parent' => 'body', 'font_name' => o['cover_org_font_name'], 'font_size' => 13,
                         'align' => 'right' },
        'cover_label' => {
          'parent' => 'body', 'font_name' => o['cover_label_font_name'], 'font_size' => 13,
          'align' => 'right', 'fill_color' => '#221E1F'
        },
        'doc_title' => {
          'parent' => 'body', 'font_name' => o['strong_font_name'], 'font_size' => 18,
          'align' => 'center', 'margin_bottom' => 36
        }
      }
    end

    def heading_styles
      (1..6).to_h do |level|
        attrs = style_from('title-style', 'title-style', level: level)
        attrs['parent'] = 'body'
        attrs['font_name'] = (@profile['style_overrides'] || {})['strong_font_name']
        attrs['keep_together'] = true
        attrs['align'] = 'left' if level == 1
        ["heading_#{level}", attrs]
      end
    end

    def list_styles
      o = @profile['style_overrides'] || {}
      attrs = style_from(nil, 'list-style').merge('parent' => 'body')
      {
        'list_bullet' => attrs,
        'list_ordered' => attrs,
        'list_marker' => { 'parent' => 'body', 'font_name' => o['list_marker_font_name'] }
      }
    end

    def section_styles
      (1..6).to_h do |level|
        ["section_body_#{level}", { 'parent' => 'body', 'margin_left' => (level - 1) * 12 }]
      end
    end

    def adapter_rules
      {
        'generated_from' => stylesheet_name,
        'profile' => File.basename(@profile_path),
        'stylesheet' => stylesheet_name,
        'metadata' => {
          'root' => 'bibdata',
          'fields' => @profile['metadata_fields'] || {}
        },
        'cover' => { 'fields' => @profile['cover_fields'] || [] },
        'sections' => { 'container' => 'sections' },
        'element_mapping' => @profile['element_mapping'] || {},
        'paragraph_styles' => @profile['paragraph_styles'] || {},
        'inline_styles' => @profile['inline_styles'] || {},
        'span_class_styles' => @profile['span_class_styles'] || {},
        'block_level_elements' => @profile['block_level_elements'] || [],
        'skip_metadata_elements' => @profile['skip_metadata_elements'] || [],
        'skip_elements' => @profile['skip_elements'] || [],
        'tab_replacements' => @profile['tab_replacements'] || {},
        'heading' => { 'source' => (@profile['selectors'] || {})['heading'] || 'fmt-title' },
        'selectors' => @profile['selectors'] || {},
        'xsl_templates' => @templates.select { |template| template['match'] }
      }
    end

    def flow_rules
      {
        'generated_from' => stylesheet_name,
        'profile' => File.basename(@profile_path),
        'stylesheet' => stylesheet_name,
        'xsl_variables' => @variables,
        'xsl_templates' => @templates.select { |template| template['name'] },
        'page_sequences' => page_sequences,
        'cover_content' => @profile['cover_content'] || [],
        'section' => {
          'heading_style' => '{{title_style_id}}',
          'body_style' => '{{style_id}}',
          'insert_page_break_before' => true,
          'insert_page_break_after_section' => true
        },
        'content_to_flowable' => {
          'Paragraph' => 'text_paragraph', 'Table' => 'table', 'List' => 'list',
          'Image' => 'image', 'Preformatted' => 'preformatted', 'PageBreak' => 'page_break'
        },
        'style_resolution' => {
          'paragraph' => 'resolve_from_style_id',
          'heading' => 'resolve_from_title_style_id',
          'table_cell' => 'resolve_from_table_cell_style',
          'list_item' => 'resolve_from_list_style'
        },
        'toc' => { 'styles' => { 'entry' => 'toc_entry', 'sub' => 'toc_entry_sub' } }
      }
    end

    def page_sequences
      names = @templates.filter_map { |template| template['name'] }
      sequences = [{ 'role' => 'cover', 'header' => nil, 'footer' => nil, 'build_content' => 'cover_content' }]
      if names.include?('back-page')
        sequences << { 'role' => 'back_of_cover', 'header' => nil, 'footer' => nil, 'page_break_after' => true }
      end
      if names.any? { |name| name.include?('preface') }
        sequences << { 'role' => 'preface', 'header' => header_template, 'footer' => '%d', 'header_align' => 'right' }
      end
      sequences << { 'role' => 'body', 'header' => header_template, 'footer' => '%d', 'header_align' => 'right' }
      if names.include?('insertMainSectionsPageSequences')
        sequences << { 'role' => 'bibliography', 'header' => header_template, 'footer' => '%d',
                       'header_align' => 'right' }
      end
      sequences
    end

    def header_template
      return nil unless @templates.any? { |template| template['name'] == 'insertHeaderEven' }

      @profile['header_template']
    end

    def extract_attribute_sets
      @document.xpath('//xsl:attribute-set', 'xsl' => XSL_NS).to_h do |node|
        attrs = node.xpath('./xsl:attribute', 'xsl' => XSL_NS).to_h do |attribute|
          [attribute['name'], attribute.text.strip]
        end
        [node['name'], attrs]
      end
    end

    def extract_variables
      @document.xpath('//xsl:variable', 'xsl' => XSL_NS).to_h do |node|
        [node['name'], node.text.strip]
      end.reject { |_name, value| value.empty? } # rubocop:disable Style/MultilineBlockChain -- idiomatic Hash.to_h.reject
    end

    def extract_templates
      @document.xpath('//xsl:template', 'xsl' => XSL_NS).map do |node|
        attributes = node.xpath('.//xsl:attribute', 'xsl' => XSL_NS).map do |attribute|
          condition = attribute.at_xpath('ancestor::xsl:if', 'xsl' => XSL_NS)
          {
            'name' => attribute['name'],
            'value' => attribute.text.strip,
            'test' => condition&.[]('test')
          }.compact
        end
        {
          'name' => node['name'],
          'match' => node['match'],
          'mode' => node['mode'],
          'priority' => node['priority'],
          'use_attribute_sets' => node['use-attribute-sets'],
          'attributes' => attributes,
          'output_elements' => node.css('*').select do |child|
            child.namespace && child.namespace.href == FO_NS
          end.map(&:name).uniq
        }.compact
      end
    end

    def style_from(attribute_set_name, refine_name = nil, level: nil)
      attrs = @attribute_sets.fetch(attribute_set_name, {}).dup
      attrs.merge!(refine_attributes(refine_name, level)) if refine_name
      attrs.each_with_object({}) do |(name, value), result|
        key = style_key(name)
        next unless key

        result[key] = style_value(key, value)
      end
    end

    def refine_attributes(name, level)
      template = @templates.find { |item| item['name'] == "refine_#{name}" }
      return {} unless template

      attributes = {}
      template.fetch('attributes', []).each do |attribute|
        next unless condition_matches_level?(attribute['test'], level)

        attributes[attribute['name']] = attribute['value']
      end
      attributes
    end

    def style_key(name)
      {
        'font-family' => 'font_name', 'font-size' => 'font_size',
        'font-weight' => 'font_weight', 'font-style' => 'font_style',
        'color' => 'fill_color', 'line-height' => 'line_spacing',
        'text-align' => 'align', 'margin-left' => 'margin_left',
        'margin-right' => 'margin_right', 'margin-top' => 'margin_top',
        'margin-bottom' => 'margin_bottom', 'space-before' => 'margin_top',
        'space-after' => 'margin_bottom', 'text-indent' => 'text_indent'
      }[name]
    end

    def style_value(key, value)
      return primary_font(value) if key == 'font_name'
      return value.to_f if key == 'font_size' && value.to_s.match?(/[\d.]+pt\z/)
      return value.to_f if key == 'line_spacing' && value.to_s.match?(/\A[\d.]+\z/)
      return value.to_sym.to_s if key == 'align'

      value
    end

    def primary_font(value)
      value.to_s.split(',').first.strip.gsub(/["']/, '')
    end

    def condition_matches_level?(test, level)
      return true unless test
      return false unless level

      match = test.match(/\$level\s*(=|>=)\s*(\d+)/)
      return false unless match

      match[1] == '=' ? level == match[2].to_i : level >= match[2].to_i
    end

    def length(value, fallback)
      value && !value.empty? ? "#{value}mm" : fallback
    end

    def yaml_file(value)
      "# Generated from #{stylesheet_name} by scripts/xsl_to_config.rb.\n" \
        "# DO NOT EDIT BY HAND — edit the XSL and rerun the generator.\n\n" \
        "#{YAML.dump(value).delete_prefix("---\n")}"
    end
  end
end

xsl_path = ARGV[0]
output_dir = ARGV[1]
profile_arg = ARGV[2] && File.expand_path(ARGV[2])

unless xsl_path && output_dir
  warn 'usage: xsl_to_config.rb <xsl-path> <output-dir> [profile-path]'
  exit 2
end

XslConfigGenerator.generate(
  xsl_path: xsl_path,
  output_dir: output_dir,
  profile: profile_arg || XslConfigGenerator::DEFAULT_PROFILE
)
