# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::Configuration do
  let(:site) { double("Jekyll::Site") }
  let(:config_hash) { {} }

  before do
    allow(site).to receive(:config).and_return(config_hash)
    allow(site).to receive(:source).and_return("/test/site")
  end

  describe "#initialize" do
    context "with full valid configuration" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "enabled" => true,
            "max_width" => 1200,
            "max_height" => 800,
            "quality" => 90
          }
        }
      end

      it "parses all configuration options correctly" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
        expect(config.max_width).to eq(1200)
        expect(config.max_height).to eq(800)
        expect(config.quality).to eq(90)
      end
    end

    context "with partial configuration" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "max_width" => 800
          }
        }
      end

      it "uses defaults for missing values" do
        config = described_class.new(site)

        expect(config.enabled?).to be true # default
        expect(config.max_width).to eq(800)  # specified
        expect(config.max_height).to be_nil  # not specified
        expect(config.quality).to eq(85) # default
      end
    end

    context "with no img_optimizer configuration" do
      let(:config_hash) { {} }

      it "uses all defaults" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
        expect(config.max_width).to be_nil
        expect(config.max_height).to be_nil
        expect(config.quality).to eq(85)
      end
    end

    context "with invalid quality value" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "quality" => 150 # invalid, must be 0-100
          }
        }
      end

      it "falls back to default quality" do
        config = described_class.new(site)
        expect(config.quality).to eq(85)
      end
    end

    context "with negative quality" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "quality" => -10
          }
        }
      end

      it "falls back to default quality" do
        config = described_class.new(site)
        expect(config.quality).to eq(85)
      end
    end

    context "with invalid max dimensions" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "max_width" => -100,
            "max_height" => 0
          }
        }
      end

      it "treats invalid dimensions as not set" do
        config = described_class.new(site)
        expect(config.max_width).to be_nil
        expect(config.max_height).to be_nil
      end
    end
  end

  describe "#enabled?" do
    context "when explicitly disabled" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "enabled" => false
          }
        }
      end

      it "returns false" do
        config = described_class.new(site)
        expect(config.enabled?).to be false
      end
    end

    context "when explicitly enabled" do
      let(:config_hash) do
        {
          "img_optimizer" => {
            "enabled" => true
          }
        }
      end

      it "returns true" do
        config = described_class.new(site)
        expect(config.enabled?).to be true
      end
    end
  end

  describe "#cache_dir" do
    it "returns cache directory path" do
      config = described_class.new(site)
      expect(config.cache_dir).to eq("/test/site/.jekyll-cache/jekyll-auto-thumbnails")
    end
  end
end
