# frozen_string_literal: true

require "spec_helper"

# Contract specs for SimpleCov 1.0 migration (#48):
# gemspec constraints, resolved majors, and skip vs deprecated add_filter.
RSpec.describe SimpleCov do
  describe "gemspec development dependencies" do
    let(:gemspec) { Gem::Specification.load(File.expand_path("../jekyll-auto-thumbnails.gemspec", __dir__)) }

    # Asserts jekyll-auto-thumbnails.gemspec pins simplecov ~> 1.0.
    it "requires simplecov ~> 1.0" do
      dep = gemspec.dependencies.find { |d| d.name == "simplecov" }
      expect(dep).not_to be_nil
      expect(dep.requirement).to eq(Gem::Requirement.new("~> 1.0"))
    end

    # Asserts jekyll-auto-thumbnails.gemspec pins simplecov-cobertura ~> 4.0.
    it "requires simplecov-cobertura ~> 4.0" do
      dep = gemspec.dependencies.find { |d| d.name == "simplecov-cobertura" }
      expect(dep).not_to be_nil
      expect(dep.requirement).to eq(Gem::Requirement.new("~> 4.0"))
    end
  end

  describe "resolved gem majors" do
    # Asserts the locked/loaded SimpleCov is 1.x at suite runtime.
    it "loads simplecov 1.x" do
      expect(described_class::VERSION).to match(/\A1\./)
    end

    # Asserts the locked/loaded simplecov-cobertura is 4.x at suite runtime.
    it "loads simplecov-cobertura 4.x" do
      version = Gem.loaded_specs.fetch("simplecov-cobertura").version
      expect(version).to be >= Gem::Version.new("4.0")
      expect(version).to be < Gem::Version.new("5.0")
    end
  end

  describe "spec_helper configuration" do
    # Asserts spec/spec_helper.rb uses skip for spec/ and vendor/ and does not use add_filter.
    it "uses skip instead of add_filter for spec and vendor paths" do
      helper = File.read(File.expand_path("spec_helper.rb", __dir__))
      expect(helper).not_to match(/\badd_filter\b/)
      expect(helper).to match(%r{\bskip\s+["']/?spec/?["']})
      expect(helper).to match(%r{\bskip\s+["']/?vendor/?["']})
    end
  end
end
