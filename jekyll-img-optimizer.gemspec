# frozen_string_literal: true

require_relative "lib/jekyll-img-optimizer/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-img-optimizer"
  spec.version = JekyllImgOptimizer::VERSION
  spec.authors = ["Austin Keener"]
  spec.email = ["keener.austin@gmail.com"]

  spec.summary = "Automatic image optimization for Jekyll sites"
  spec.description = "Jekyll plugin that automatically generates and serves optimized image thumbnails " \
                     "for faster page loads. Scans rendered HTML, generates thumbnails with intelligent " \
                     "caching, and seamlessly replaces URLs."
  spec.homepage = "https://github.com/KeenerA/jekyll-img-optimizer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/KeenerA/jekyll-img-optimizer"
  spec.metadata["changelog_uri"] = "https://github.com/KeenerA/jekyll-img-optimizer/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
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
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "simplecov", "~> 0.22"
end

