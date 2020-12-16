# frozen_string_literal: true

require_relative 'lib/active_shotgun/version'

Gem::Specification.new do |spec|
  spec.name          = "active_shotgun"
  spec.version       = ActiveShotgun::VERSION
  spec.authors       = ["Denis <Zaratan> Pasin"]
  spec.email         = ["zaratan@hey.com"]

  spec.summary       = "Shotgun connector for active models"
  spec.description   = "Allow using a Shotgun site as a DB for Active Model objects."
  spec.homepage      = "https://github.com/zaratan/active_shotgun"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "https://github.com/zaratan/active_shotgun/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'zeitwerk', '~> 2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-faker'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'
  spec.add_development_dependency 'yard'
end
