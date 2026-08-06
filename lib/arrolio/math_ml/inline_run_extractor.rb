# frozen_string_literal: true

require 'mml'

module Arrolio
  module MathML
    # Walks a parsed Mml tree (from +Mml.parse(xml_string, version: 3)+)
    # and emits an Array of +Content::InlineRun+ values, applying
    # +baseline_shift+ and +font_size_scale+ to match the math
    # layout semantics of each MathML element.
    #
    # The extractor relies on the canonical Mml gem (plurimath/mml)
    # for parsing, keeping Arrolio free of its own MathML grammar.
    # MathML presentation elements map as follows:
    #
    #   <mi>                  → italic math run (:math_identifier)
    #   <mn>, <mo>, <mtext>   → regular math run (parent style)
    #   <ms>                  → quoted string run (parent style)
    #   <msub>                → base + subscript run
    #   <msup>                → base + superscript run
    #   <msubsup>             → base + sub + sup
    #   <munder>/<mover>      → rendered as sub/sup for visual fidelity
    #   <mfrac>               → numerator + '/' + denominator (inline)
    #   <mrow>, <mstyle>      → transparent group, recurse children
    #
    # Anything else recurses transparently.
    class InlineRunExtractor

      # Each entry is [value_attribute, child_collection_attribute, kind]
      # - value_attribute: node method returning the text content (or nil)
      # - child_collection_attribute: node method returning child
      #   elements of that type (Array)
      # - kind: :text | :identifier | :transparent | :subscript_container
      #         | :superscript_container | :fraction | :ignored
      ELEMENT_HANDLERS = {
        'Mml::V3::Mi' => [:value, :mi_value, :identifier],
        'Mml::V3::Mn' => [:value, :mn_value, :text],
        'Mml::V3::Mo' => [:value, :mo_value, :text],
        'Mml::V3::Mtext' => [:value, :mtext_value, :text],
        'Mml::V3::Ms' => [:value, :ms_value, :text],
        'Mml::V3::Mrow' => [nil, nil, :transparent_all],
        'Mml::V3::Mstyle' => [nil, nil, :transparent_all],
        'Mml::V3::Msub' => [nil, :msub_value, :subscript_container],
        'Mml::V3::Msup' => [nil, :msup_value, :superscript_container],
        'Mml::V3::Msubsup' => [nil, :msubsup_value, :subsup_container],
        'Mml::V3::Munder' => [nil, :munder_value, :subscript_container],
        'Mml::V3::Mover' => [nil, :mover_value, :superscript_container],
        'Mml::V3::Munderover' => [nil, :munderover_value, :subsup_container],
        'Mml::V3::Mfrac' => [nil, :mfrac_value, :fraction],
        'Mml::V3::Menclose' => [nil, :menclose_value, :transparent],
        'Mml::V3::Mphantom' => [nil, :mphantom_value, :transparent],
        'Mml::V3::Mpadded' => [nil, :mpadded_value, :transparent],
        'Mml::V3::Merror' => [nil, :merror_value, :transparent],
        'Mml::V3::Semantics' => [nil, :semantics_value, :transparent],
        'Mml::V3::Math' => [nil, nil, :transparent_all]
      }.freeze

      attr_reader :base_style

      def sub_sup_scale = 0.7

      def default_baseline
        ::Arrolio::Content::InlineRun::BASELINE_NORMAL
      end

      def sub_baseline
        ::Arrolio::Content::InlineRun::BASELINE_SUB
      end

      def sup_baseline
        ::Arrolio::Content::InlineRun::BASELINE_SUP
      end

      def initialize(base_style: :math)
        @base_style = base_style.to_sym
      end

      def extract(math_node)
        runs = []
        walk(math_node, runs, baseline: default_baseline, scale: 1.0,
                              style_id: base_style)
        runs
      end

      # Parse +xml_string+ as MathML and extract the runs. Returns
      # an empty Array if parsing fails.
      def self.extract_from_xml(xml_string, base_style: :math)
        return [] if xml_string.nil? || xml_string.to_s.empty?

        parsed = ::Mml.parse(xml_string.to_s, version: 3)
        new(base_style: base_style).extract(parsed)
      rescue StandardError => e
        Arrolio::Logger.warn "Mml parse failed: #{e.class}: #{e.message[0, 80]}"
        []
      end

      private

      def walk(node, runs, baseline:, scale:, style_id:)
        return unless node

        handler = ELEMENT_HANDLERS[node.class.name]
        if handler
          dispatch_handler(node, handler, runs, baseline: baseline,
                                                scale: scale, style_id: style_id)
        else
          # Unknown element: recurse transparently into all child collections.
          walk_all_children(node, runs, baseline: baseline, scale: scale,
                                        style_id: style_id)
        end
      end

      def dispatch_handler(node, handler, runs, baseline:, scale:, style_id:)
        _value_attr, child_attr, kind = handler
        effective_style = kind == :identifier ? :math_identifier : style_id
        if handler.first
          emit_text_value(node, runs, baseline: baseline, scale: scale,
                                      style_id: effective_style)
        end
        case kind
        when :identifier
          emit_collection_as(node, child_attr, runs, baseline: baseline, scale: scale,
                                                     style_id: :math_identifier)
        when :text
          emit_collection_as(node, child_attr, runs, baseline: baseline, scale: scale,
                                                     style_id: style_id)
        when :transparent
          walk_collection(node, child_attr, runs, baseline: baseline, scale: scale,
                                                  style_id: style_id)
        when :transparent_all
          walk_all_children(node, runs, baseline: baseline, scale: scale,
                                        style_id: style_id)
        when :subscript_container
          process_script_container(node, runs, baseline: baseline, scale: scale,
                                               style_id: style_id,
                                               script_baseline: sub_baseline,
                                               script_position: 1)
        when :superscript_container
          process_script_container(node, runs, baseline: baseline, scale: scale,
                                               style_id: style_id,
                                               script_baseline: sup_baseline,
                                               script_position: 1)
        when :subsup_container
          process_subsup_container(node, runs, baseline: baseline, scale: scale,
                                               style_id: style_id)
        when :fraction
          process_fraction_container(node, runs, baseline: baseline, scale: scale,
                                                 style_id: style_id)
        end
      end

      def emit_text_value(node, runs, baseline:, scale:, style_id:)
        value = safe_value(node)
        return if value.nil? || value.empty?

        runs << ::Arrolio::Content::InlineRun.new(value,
                                                  style_id: style_id,
                                                  baseline_shift: baseline,
                                                  font_size_scale: scale)
      end

      def emit_collection_as(node, attr, runs, baseline:, scale:, style_id:)
        children = safe_collection(node, attr)
        children.each { |c| walk(c, runs, baseline: baseline, scale: scale, style_id: style_id) }
      end

      def walk_collection(node, attr, runs, baseline:, scale:, style_id:)
        safe_collection(node, attr).each do |child|
          walk(child, runs, baseline: baseline, scale: scale, style_id: style_id)
        end
      end

      # For <msub>/<msup>: the node IS the container. Its children
      # are the base (first) and the script (second).
      def process_script_container(node, runs, baseline:, scale:, style_id:,
                                   script_baseline:, script_position:)
        children = all_child_elements(node)
        base = children.first
        script = children[script_position]
        if base
          walk(base, runs, baseline: baseline, scale: scale,
                           style_id: style_id)
        end
        return unless script

        walk(script, runs, baseline: script_baseline,
                           scale: reduce_scale(scale),
                           style_id: style_id)
      end

      # For <msubsup>: base + sub + sup
      def process_subsup_container(node, runs, baseline:, scale:, style_id:)
        children = all_child_elements(node)
        base = children[0]
        sub = children[1]
        sup = children[2]
        if base
          walk(base, runs, baseline: baseline, scale: scale,
                           style_id: style_id)
        end
        if sub
          walk(sub, runs, baseline: sub_baseline,
                          scale: reduce_scale(scale), style_id: style_id)
        end
        return unless sup

        walk(sup, runs, baseline: sup_baseline,
                        scale: reduce_scale(scale), style_id: style_id)
      end

      # For <mfrac>: numerator + '/' + denominator, all at reduced scale.
      def process_fraction_container(node, runs, baseline:, scale:, style_id:)
        children = all_child_elements(node)
        numerator = children[0]
        denominator = children[1]
        child_scale = reduce_scale(scale)
        if numerator
          walk(numerator, runs, baseline: sup_baseline, scale: child_scale,
                                style_id: style_id)
        end
        runs << ::Arrolio::Content::InlineRun.new('/', style_id: style_id,
                                                       baseline_shift: baseline,
                                                       font_size_scale: scale)
        return unless denominator

        walk(denominator, runs, baseline: sub_baseline, scale: child_scale,
                                style_id: style_id)
      end

      def walk_all_children(node, runs, baseline:, scale:, style_id:)
        %i[mi_value mn_value mo_value mtext_value ms_value mrow_value
           mstyle_value msub_value msup_value msubsup_value mfrac_value
           menclose_value mphantom_value mpadded_value merror_value
           mover_value munder_value munderover_value semantics_value
           msqrt_value mroot_value mtable_value math_value].each do |attr|
          safe_collection(node, attr).each do |child|
            walk(child, runs, baseline: baseline, scale: scale, style_id: style_id)
          end
        end
      end

      def all_child_elements(node)
        %i[mi_value mn_value mo_value mtext_value ms_value mrow_value
           mstyle_value msub_value msup_value msubsup_value mfrac_value
           menclose_value mphantom_value mpadded_value merror_value
           mover_value munder_value munderover_value semantics_value
           msqrt_value mroot_value mtable_value].flat_map do |attr|
          safe_collection(node, attr)
        end
      end

      def safe_collection(node, attr)
        return [] unless node.is_a?(::Mml::CommonElements)

        node.public_send(attr)
      rescue StandardError
        []
      end

      def safe_value(node)
        value = node.value
        value.is_a?(Array) ? value.join : value.to_s
      rescue StandardError
        nil
      end

      def reduce_scale(current_scale)
        (current_scale * sub_sup_scale).round(4)
      end
    end
  end
end
