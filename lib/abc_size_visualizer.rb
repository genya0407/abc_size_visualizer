# frozen_string_literal: true

require "rubocop"
require "parser/current"
require "colorized_string"
require "rouge"

require_relative "abc_size_visualizer/abc_size_calculator"
require_relative "abc_size_visualizer/integer_on_location"
require_relative "abc_size_visualizer/version"

module AbcSizeVisualizer
  class Error < StandardError; end
  # Your code goes here...
end
