# frozen_string_literal: true

require_relative "lib/jekyll-auto-thumbnails/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-auto-thumbnails"
  spec.version = JekyllAutoThumbnails::VERSION
  spec.authors = ["Texarkanine"]
  spec.email = ["texarkanine@protonmail.com"]

  spec.summary = "Automatic image optimization for Jekyll sites"
  spec.description = "Jekyll plugin that automatically generates and serves optimized image thumbnails " \
                     "for faster page loads."
  spec.homepage = "https://github.com/Texarkanine/jekyll-auto-thumbnails"
  spec.license = "AGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Texarkanine/jekyll-auto-thumbnails"
  spec.metadata["changelog_uri"] = "https://github.com/Texarkanine/jekyll-auto-thumbnails/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "*.gemspec",
    "lib/**/*.rb",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "jekyll", ">= 4.0", "< 5.0"
  spec.add_dependency "nokogiri", "~> 1.15"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.81"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.8"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1"
end
