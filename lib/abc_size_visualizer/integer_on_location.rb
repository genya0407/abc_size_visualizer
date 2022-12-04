module AbcSizeVisualizer
  class IntegerOnLocation
    attr_reader :value_by_line_num

    def initialize
      @value_by_line_num = {}
    end

    def add(node, value)
      line_num = node.loc.expression.line
      @value_by_line_num[line_num] ||= 0
      @value_by_line_num[line_num] += value
    end

    def value_at(line_num:)
      @value_by_line_num[line_num]
    end

    def to_i
      @value_by_line_num.values.sum || 0
    end

    def line_nums
      @value_by_line_num.keys
    end
  end
end
