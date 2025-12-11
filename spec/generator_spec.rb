# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllImgOptimizer::Generator do
  let(:config) { double("Configuration", cache_dir: "/test/cache", quality: 85) }
  let(:site_source) { "/test/site" }
  let(:generator) { described_class.new(config, site_source) }

  describe "#imagemagick_available?" do
    it "returns true when convert is available" do
      allow(generator).to receive(:system).with("which convert > /dev/null 2>&1").and_return(true)
      expect(generator.imagemagick_available?).to be true
    end

    it "returns false when convert is not available" do
      allow(generator).to receive(:system).with("which convert > /dev/null 2>&1").and_return(false)
      expect(generator.imagemagick_available?).to be false
    end
  end

  describe "#build_thumbnail_filename" do
    it "constructs filename with all components" do
      result = generator.build_thumbnail_filename("photo", "abc123", 300, 200, ".jpg")
      expect(result).to eq("photo_thumb-abc123-300x200.jpg")
    end

    it "handles nil width" do
      result = generator.build_thumbnail_filename("photo", "abc123", nil, 400, ".jpg")
      expect(result).to eq("photo_thumb-abc123-x400.jpg")
    end

    it "handles nil height" do
      result = generator.build_thumbnail_filename("photo", "abc123", 300, nil, ".jpg")
      expect(result).to eq("photo_thumb-abc123-300x.jpg")
    end
  end

  describe "#generate" do
    let(:source_path) { "/test/site/photo.jpg" }
    let(:cached_path) { "/test/cache/photo_thumb-abc123-300x200.jpg" }

    before do
      allow(JekyllImgOptimizer::UrlResolver).to receive(:to_filesystem_path)
        .with("/photo.jpg", site_source).and_return(source_path)
      allow(File).to receive(:exist?).with(source_path).and_return(true)
      allow(JekyllImgOptimizer::DigestCalculator).to receive(:short_digest)
        .with(source_path).and_return("abc123")
      allow(FileUtils).to receive(:mkdir_p)
    end

    context "when thumbnail exists in cache" do
      it "returns cached path without regenerating" do
        allow(File).to receive(:exist?).with(cached_path).and_return(true)
        
        result = generator.generate("/photo.jpg", 300, 200)
        expect(result).to eq(cached_path)
      end
    end

    context "when thumbnail needs generation" do
      before do
        allow(File).to receive(:exist?).with(cached_path).and_return(false)
        allow(generator).to receive(:shell_generate).and_return(true)
        # Mock file sizes: thumbnail smaller than original (good)
        allow(File).to receive(:size).with(source_path).and_return(100_000)
        allow(File).to receive(:size).with(cached_path).and_return(40_000)
      end

      it "generates thumbnail and returns path" do
        result = generator.generate("/photo.jpg", 300, 200)

        expect(generator).to have_received(:shell_generate)
        expect(result).to eq(cached_path)
      end
    end

    context "when source file doesn't exist" do
      it "returns nil" do
        allow(File).to receive(:exist?).with(source_path).and_return(false)

        result = generator.generate("/photo.jpg", 300, 200)
        expect(result).to be_nil
      end
    end

    context "when generated thumbnail is larger than original" do
      before do
        allow(File).to receive(:exist?).with(cached_path).and_return(false)
        allow(generator).to receive(:shell_generate).and_return(true)
        allow(File).to receive(:size).with(source_path).and_return(50_000)
        allow(File).to receive(:size).with(cached_path).and_return(60_000)  # Larger!
        allow(FileUtils).to receive(:rm_f)
      end

      it "deletes thumbnail and returns nil" do
        result = generator.generate("/photo.jpg", 300, 200)

        expect(FileUtils).to have_received(:rm_f).with(cached_path)
        expect(result).to be_nil
      end
    end
  end
end

