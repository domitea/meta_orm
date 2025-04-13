# frozen_string_literal: true

require_relative "lib/meta_orm/version"

Gem::Specification.new do |spec|
  spec.name = "meta_orm"
  spec.version = MetaOrm::VERSION
  spec.authors = ["Dominik Matoulek"]
  spec.email = ["domitea@gmail.com"]

  spec.summary = "Declarative and introspectable data modeling layer on top of Sequel"
  spec.description = "MetaORM is a lightweight, extensible Ruby DSL for defining scientific and sensor-oriented data models. Built on top of Sequel, it adds support for units, value ranges, enums, test data generation, validations, and data transformations — all with introspection-friendly metadata, designed for edge computing, experiment automation, or embedded systems."
  spec.homepage = "https://github.com/domitea/meta_orm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "sequel", "~> 5.91"
  spec.add_dependency "zeitwerk", "~> 2.6.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
