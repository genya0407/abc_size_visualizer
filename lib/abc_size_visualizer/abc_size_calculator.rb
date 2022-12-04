# Based on https://github.com/rubocop/rubocop/blob/master/lib/rubocop/cop/metrics/utils/abc_size_calculator.rb

module AbcSizeVisualizer
  # > ABC is .. a software size metric .. computed by counting the number
  # > of assignments, branches and conditions for a section of code.
  # > http://c2.com/cgi/wiki?AbcMetric
  #
  # We separate the *calculator* from the *cop* so that the calculation,
  # the formula itself, is easier to test.
  class AbcSizeCalculator
    include RuboCop::Cop::Metrics::Utils::IteratingBlock
    include RuboCop::Cop::Metrics::Utils::RepeatedCsendDiscount
    prepend RuboCop::Cop::Metrics::Utils::RepeatedAttributeDiscount

    # > Branch -- an explicit forward program branch out of scope -- a
    # > function call, class method call ..
    # > http://c2.com/cgi/wiki?AbcMetric
    BRANCH_NODES = %i[send csend yield].freeze

    # > Condition -- a logical/Boolean test, == != <= >= < > else case
    # > default try catch ? and unary conditionals.
    # > http://c2.com/cgi/wiki?AbcMetric
    CONDITION_NODES = RuboCop::Cop::Metrics::CyclomaticComplexity::COUNTED_NODES.freeze

    def self.calculate(node, discount_repeated_attributes: false)
      new(node, discount_repeated_attributes:).calculate
    end

    # TODO: move to rubocop-ast
    ARGUMENT_TYPES = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg].freeze

    private_constant :BRANCH_NODES, :CONDITION_NODES, :ARGUMENT_TYPES

    attr_reader :assignment, :branch, :condition

    def initialize(node)
      @assignment = IntegerOnLocation.new
      @branch = IntegerOnLocation.new
      @condition = IntegerOnLocation.new
      @node = node
      reset_repeated_csend
    end

    def abc_by_line_num
      @abc_by_line_num ||= [@assignment, @branch, @condition].map(&:line_nums).flatten.map do |line_num|
        [
          line_num,
          {assignment: @assignment, branch: @branch, condition: @condition}.transform_values do
            _1.value_at(line_num:) || 0
          end
        ]
      end.to_h
    end

    def calculate
      visit_depth_last(@node) { |child| calculate_node(child) }

      [
        Math.sqrt((@assignment.to_i**2) + (@branch.to_i**2) + (@condition.to_i**2)).round(2),
        "<#{@assignment.to_i}, #{@branch.to_i}, #{@condition.to_i}>"
      ]
    end

    def evaluate_branch_nodes(node)
      if node.comparison_method?
        @condition.add(node, 1)
      else
        @branch.add(node, 1)
        @condition.add(node, 1) if node.csend_type? && !discount_for_repeated_csend?(node)
      end
    end

    def evaluate_condition_node(node)
      @condition.add(node, 1) if else_branch?(node)
      @condition.add(node, 1)
    end

    def else_branch?(node)
      %i[case if].include?(node.type) && node.else? && node.loc.else.is?("else")
    end

    private

    def visit_depth_last(node, &block)
      node.each_child_node { |child| visit_depth_last(child, &block) }
      yield node
    end

    def calculate_node(node)
      @assignment.add(node, 1) if assignment?(node)

      if branch?(node)
        evaluate_branch_nodes(node)
      elsif condition?(node)
        evaluate_condition_node(node)
      end
    end

    def assignment?(node)
      return compound_assignment(node) if node.masgn_type? || node.shorthand_asgn?

      node.for_type? ||
        (node.respond_to?(:setter_method?) && node.setter_method?) ||
        simple_assignment?(node) ||
        argument?(node)
    end

    def compound_assignment(node)
      # Methods setter cannot be detected for multiple assignments
      # and shorthand assigns, so we'll count them here instead
      children = node.masgn_type? ? node.children[0].children : node.children

      will_be_miscounted = children.count do |child|
        child.respond_to?(:setter_method?) && !child.setter_method?
      end
      @assignment.add(node, will_be_miscounted)

      false
    end

    def simple_assignment?(node)
      if !node.equals_asgn?
        false
      elsif node.lvasgn_type?
        reset_on_lvasgn(node)
        capturing_variable?(node.children.first)
      else
        true
      end
    end

    def capturing_variable?(name)
      # TODO: Remove `Symbol#to_s` after supporting only Ruby >= 2.7.
      name && !name.to_s.start_with?("_")
    end

    def branch?(node)
      BRANCH_NODES.include?(node.type)
    end

    def argument?(node)
      ARGUMENT_TYPES.include?(node.type) && capturing_variable?(node.children.first)
    end

    def condition?(node)
      return false if iterating_block?(node) == false

      CONDITION_NODES.include?(node.type)
    end
  end
end
