# frozen_string_literal: true

module Arrolio
  module Harness
    module TextDiff
      module_function

      def tokens(text)
        text.to_s.downcase.gsub(/[^a-z0-9\s]/i, ' ').split
      end

      def similarity(a, b)
        ta = tokens(a).to_set
        tb = tokens(b).to_set
        return 1.0 if ta.empty? && tb.empty?
        return 0.0 if ta.empty? || tb.empty?

        (ta & tb).size.to_f / (ta | tb).size
      end

      def paragraphs(text)
        text.to_s.split(/\n\s*\n/).map(&:strip).reject(&:empty?)
      end

      def match_paragraphs(ours, theirs)
        ours_paras = paragraphs(ours)
        theirs_paras = paragraphs(theirs)
        theirs_used = Array.new(theirs_paras.length, false)

        ours_paras.map do |op|
          best_idx = nil
          best_sim = 0.0
          theirs_paras.each_with_index do |tp, i|
            next if theirs_used[i]

            s = similarity(op, tp)
            if s > best_sim
              best_sim = s
              best_idx = i
            end
          end

          if best_idx && best_sim >= 0.3
            theirs_used[best_idx] = true
            { ours: op, theirs: theirs_paras[best_idx], similarity: best_sim }
          else
            { ours: op, theirs: nil, similarity: 0.0 }
          end
        end
      end
    end
  end
end
