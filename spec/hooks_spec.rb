# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllImgOptimizer::Hooks do
  let(:site_data) { {} }
  let(:site) do
    double("Jekyll::Site",
           config: {},
           source: "/test/site",
           dest: "/test/_site",
           data: site_data)
  end
  let(:doc) { double("Jekyll::Document", output: "<article><img src='/photo.jpg' width='300'></article>") }

  describe ".initialize_system" do
    it "creates configuration, registry, and generator" do
      described_class.initialize_system(site)

      expect(site.data["img_optimizer_config"]).to be_a(JekyllImgOptimizer::Configuration)
      expect(site.data["img_optimizer_registry"]).to be_a(JekyllImgOptimizer::Registry)
      expect(site.data["img_optimizer_generator"]).to be_a(JekyllImgOptimizer::Generator)
    end

    it "skips when disabled" do
      disabled_site = double("Jekyll::Site",
                             config: { "img_optimizer" => { "enabled" => false } },
                             source: "/test/site",
                             data: {})

      described_class.initialize_system(disabled_site)

      expect(disabled_site.data).to be_empty
    end
  end

  describe ".process_site" do
    let(:config) { double("Configuration", enabled?: true, max_width: 800, max_height: 600, cache_dir: "/cache") }
    let(:registry) { JekyllImgOptimizer::Registry.new }
    let(:generator) { double("Generator") }
    let(:doc1) { double("Document", output: "<article><img src='/p1.jpg' width='300'></article>") }
    let(:doc2) { double("Document", output: "<article><img src='/p2.jpg' width='400'></article>") }

    before do
      site_data["img_optimizer_config"] = config
      site_data["img_optimizer_registry"] = registry
      site_data["img_optimizer_generator"] = generator

      allow(site).to receive(:documents).and_return([doc1])
      allow(site).to receive(:pages).and_return([doc2])
      allow(generator).to receive(:imagemagick_available?).and_return(true)
      allow(generator).to receive(:generate).and_return(nil)
      allow(doc1).to receive(:output=)
      allow(doc2).to receive(:output=)
    end

    it "scans all documents and pages" do
      allow(generator).to receive(:generate).and_return("/cache/thumb.jpg")

      described_class.process_site(site)

      expect(registry.registered?("/p1.jpg")).to be true
      expect(registry.registered?("/p2.jpg")).to be true
    end

    it "generates thumbnails and replaces URLs" do
      registry.register("/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/p1.jpg", 300, 200)
        .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(generator).to have_received(:generate).with("/p1.jpg", 300, 200).at_least(:once)
      expect(doc1).to have_received(:output=)
    end
  end

  describe ".copy_thumbnails" do
    let(:config) { double("Configuration", enabled?: true, cache_dir: "/cache") }
    let(:url_map) { { "/photo.jpg" => "/photo_thumb-abc123-300x200.jpg" } }

    before do
      site_data["img_optimizer_config"] = config
      site_data["img_optimizer_url_map"] = url_map

      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp)
    end

    it "copies thumbnails from cache to _site" do
      described_class.copy_thumbnails(site)

      expect(FileUtils).to have_received(:cp).with(
        "/cache/photo_thumb-abc123-300x200.jpg",
        "/test/_site/photo_thumb-abc123-300x200.jpg"
      )
    end
  end
end

