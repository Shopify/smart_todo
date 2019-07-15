# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "smart_todo/version"

Gem::Specification.new do |spec|
  spec.name          = "smart_todo"
  spec.version       = SmartTodo::VERSION
  spec.authors       = ["Shopify"]
  spec.email         = ["rails@shopify.com"]

  spec.summary       = "Enhance todo's comments in your codebase."
  spec.description   = <<~EOM
    SmartTodo is a tool designed to assign specific users on todo's task
    written in your codebase and help assignees be reminded when it's time to commit
    to their todo's.
  EOM
  spec.homepage      = "https://github.com/shopify/smart_todo"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = ['smart_todo']
  spec.require_paths = ["lib"]

  spec.add_development_dependency("bundler", "~> 1.17")
  spec.add_development_dependency("rake", "~> 10.0")
  spec.add_development_dependency("minitest", "~> 5.0")
  spec.add_development_dependency("webmock")
  spec.add_development_dependency("rubocop")
end
