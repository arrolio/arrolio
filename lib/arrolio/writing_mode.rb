# frozen_string_literal: true

module Arrolio
  # Writing mode enumeration for vertical/RTL layout. Controls
  # the inline and block progression directions used by the
  # layout engine. The values map to XSL-FO writing-mode
  # property values.
  #
  # +LR_TB+ — left-to-right inline, top-to-bottom block (Latin, CJK).
  # +RL_TB+ — right-to-left inline, top-to-bottom block (Arabic, Hebrew).
  # +TB_RL+ — top-to-bottom inline, right-to-left block (vertical CJK).
  class WritingMode
    LR_TB = :lr_tb
    RL_TB = :rl_tb
    TB_RL = :tb_rl
    DEFAULT = LR_TB

    ALL = [LR_TB, RL_TB, TB_RL].freeze

    attr_reader :mode

    def initialize(mode = DEFAULT)
      @mode = mode.to_sym
      freeze
    end

    def vertical?
      @mode == TB_RL
    end

    def rtl?
      @mode == RL_TB
    end

    def ltr?
      @mode == LR_TB
    end

    # Returns the inline progression direction as a 2D vector.
    # +[1, 0]+ = rightward, +[-1, 0]+ = leftward, +[0, 1]+ = downward.
    def inline_direction
      case @mode
      when LR_TB then [1, 0]
      when RL_TB then [-1, 0]
      when TB_RL then [0, 1]
      end
    end

    # Returns the block progression direction as a 2D vector.
    def block_direction
      case @mode
      when LR_TB, RL_TB then [0, -1]
      when TB_RL then [-1, 0]
      end
    end

    def ==(other)
      other.is_a?(self.class) && mode == other.mode
    end
    alias eql? ==

    def hash
      [self.class, mode].hash
    end

    def self.parse(value)
      case value.to_s.downcase.tr('-', '_')
      when 'lr_tb', 'lrtb' then new(LR_TB)
      when 'rl_tb', 'rltb' then new(RL_TB)
      when 'tb_rl', 'tbrl' then new(TB_RL)
      else new(DEFAULT)
      end
    end
  end
end
