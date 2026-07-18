# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::Generator do
  let(:config) { double("Configuration", cache_dir: "/test/cache", quality: 85) }
  let(:site_source) { "/test/site" }
  let(:generator) { described_class.new(config, site_source) }

  describe "#imagemagick_available?" do
    it "delegates to ImageMagickWrapper.available?" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:available?).and_return(true)
      expect(generator.imagemagick_available?).to be true
      expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:available?)
    end

    it "returns false when ImageMagick is not available" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:available?).and_return(false)
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
      allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
        .with("/photo.jpg", site_source).and_return(source_path)
      allow(File).to receive(:exist?).with(source_path).and_return(true)
      allow(JekyllAutoThumbnails::DigestCalculator).to receive(:short_digest)
        .with(source_path).and_return("abc123")
      allow(FileUtils).to receive(:mkdir_p)
    end

    context "when thumbnail exists in cache" do
      it "returns cached path without regenerating" do
        allow(File).to receive(:exist?).with(cached_path).and_return(true)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_convert)

        result = generator.generate("/photo.jpg", 300, 200)
        expect(result).to eq(cached_path)
        expect(JekyllAutoThumbnails::ImageMagickWrapper).not_to have_received(:execute_convert)
      end
    end

    context "when thumbnail needs generation" do
      before do
        allow(File).to receive(:exist?).with(cached_path).and_return(false)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_convert).and_return(true)
        allow(File).to receive(:size).with(source_path).and_return(100_000)
        allow(File).to receive(:size).with(cached_path).and_return(40_000)
      end

      it "generates thumbnail and returns path" do
        result = generator.generate("/photo.jpg", 300, 200)

        expect(FileUtils).to have_received(:mkdir_p).with("/test/cache")
        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(source_path, "-resize", "300x200>", "-quality", "85", cached_path)
        expect(result).to eq(cached_path)
      end

      it "omits quality for non-JPEG sources" do
        png_source = "/test/site/photo.png"
        png_cached = "/test/cache/photo_thumb-abc123-300x200.png"
        allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
          .with("/photo.png", site_source).and_return(png_source)
        allow(File).to receive(:exist?).with(png_source).and_return(true)
        allow(JekyllAutoThumbnails::DigestCalculator).to receive(:short_digest)
          .with(png_source).and_return("abc123")
        allow(File).to receive(:exist?).with(png_cached).and_return(false)
        allow(File).to receive(:size).with(png_source).and_return(100_000)
        allow(File).to receive(:size).with(png_cached).and_return(40_000)

        generator.generate("/photo.png", 300, 200)

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(png_source, "-resize", "300x200>", png_cached)
      end

      it "applies quality for .jpeg extension" do
        jpeg_source = "/test/site/photo.jpeg"
        jpeg_cached = "/test/cache/photo_thumb-abc123-300x200.jpeg"
        allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
          .with("/photo.jpeg", site_source).and_return(jpeg_source)
        allow(File).to receive(:exist?).with(jpeg_source).and_return(true)
        allow(JekyllAutoThumbnails::DigestCalculator).to receive(:short_digest)
          .with(jpeg_source).and_return("abc123")
        allow(File).to receive(:exist?).with(jpeg_cached).and_return(false)
        allow(File).to receive(:size).with(jpeg_source).and_return(100_000)
        allow(File).to receive(:size).with(jpeg_cached).and_return(40_000)

        generator.generate("/photo.jpeg", 300, 200)

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(jpeg_source, "-resize", "300x200>", "-quality", "85", jpeg_cached)
      end

      it "applies quality for uppercase .JPG extension" do
        jpg_source = "/test/site/photo.JPG"
        jpg_cached = "/test/cache/photo_thumb-abc123-300x200.JPG"
        allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
          .with("/photo.JPG", site_source).and_return(jpg_source)
        allow(File).to receive(:exist?).with(jpg_source).and_return(true)
        allow(JekyllAutoThumbnails::DigestCalculator).to receive(:short_digest)
          .with(jpg_source).and_return("abc123")
        allow(File).to receive(:exist?).with(jpg_cached).and_return(false)
        allow(File).to receive(:size).with(jpg_source).and_return(100_000)
        allow(File).to receive(:size).with(jpg_cached).and_return(40_000)

        generator.generate("/photo.JPG", 300, 200)

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(jpg_source, "-resize", "300x200>", "-quality", "85", jpg_cached)
      end

      it "builds open-ended geometry when width is nil" do
        nil_width_cached = "/test/cache/photo_thumb-abc123-x200.jpg"
        allow(File).to receive(:exist?).with(nil_width_cached).and_return(false)
        allow(File).to receive(:size).with(nil_width_cached).and_return(40_000)

        generator.generate("/photo.jpg", nil, 200)

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(source_path, "-resize", "x200>", "-quality", "85", nil_width_cached)
      end

      it "builds open-ended geometry when height is nil" do
        nil_height_cached = "/test/cache/photo_thumb-abc123-300x.jpg"
        allow(File).to receive(:exist?).with(nil_height_cached).and_return(false)
        allow(File).to receive(:size).with(nil_height_cached).and_return(40_000)

        generator.generate("/photo.jpg", 300, nil)

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_convert)
          .with(source_path, "-resize", "300x>", "-quality", "85", nil_height_cached)
      end

      it "returns nil when ImageMagick convert fails" do
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_convert).and_return(false)

        expect(generator.generate("/photo.jpg", 300, 200)).to be_nil
      end
    end

    context "when source file doesn't exist" do
      it "returns nil" do
        allow(File).to receive(:exist?).with(source_path).and_return(false)

        result = generator.generate("/photo.jpg", 300, 200)
        expect(result).to be_nil
      end
    end

    context "when the URL cannot be resolved to a filesystem path" do
      it "returns nil without checking File.exist?" do
        allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
          .with("/photo.jpg", site_source).and_return(nil)
        allow(File).to receive(:exist?)

        expect(generator.generate("/photo.jpg", 300, 200)).to be_nil
        expect(File).not_to have_received(:exist?)
      end
    end

    context "when generated thumbnail is larger than original" do
      let(:logger) { double("Jekyll::Logger", warn: nil) }

      before do
        allow(File).to receive(:exist?).with(cached_path).and_return(false)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_convert).and_return(true)
        allow(File).to receive(:size).with(source_path).and_return(50_000)
        allow(File).to receive(:size).with(cached_path).and_return(60_000) # Larger!
        allow(FileUtils).to receive(:rm_f)
        allow(Jekyll).to receive(:logger).and_return(logger)
      end

      it "deletes thumbnail and returns nil" do
        result = generator.generate("/photo.jpg", 300, 200)

        expect(logger).to have_received(:warn).with(
          "AutoThumbnails:",
          "Thumbnail larger than original (60000 > 50000), deleting #{cached_path}"
        )
        expect(FileUtils).to have_received(:rm_f).with(cached_path)
        expect(result).to be_nil
      end
    end
  end
end
