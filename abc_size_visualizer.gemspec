# frozen_string_literal: true

require_relative "lib/abc_size_visualizer/version"

Gem::Specification.new do |spec|
  spec.name = "abc_size_visualizer"
  spec.version = AbcSizeVisualizer::VERSION
  spec.authors = ["Yusuke Sangenya"]
  spec.email = ["longinus.eva@gmail.com"]

  spec.summary = "Visualize ABC size."
  spec.description = "Visualize ABC size"
  spec.homepage = "https://github.com/genya0407/abc_size_visualizer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features|docs)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize"
  spec.add_dependency "rubocop"
  spec.add_dependency "rouge"
  spec.add_development_dependency "debug"
end
