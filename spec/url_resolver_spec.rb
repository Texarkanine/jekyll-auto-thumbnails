# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::UrlResolver do
  describe ".external?" do
    context "with http URL" do
      it "returns true" do
        expect(described_class.external?("http://example.com/image.jpg")).to be true
      end
    end

    context "with https URL" do
      it "returns true" do
        expect(described_class.external?("https://example.com/image.jpg")).to be true
      end
    end

    context "with protocol-relative URL" do
      it "returns true" do
        expect(described_class.external?("//example.com/image.jpg")).to be true
      end
    end

    context "with absolute path" do
      it "returns false" do
        expect(described_class.external?("/assets/image.jpg")).to be false
      end
    end

    context "with relative path" do
      it "returns false for ./ prefix" do
        expect(described_class.external?("./image.jpg")).to be false
      end

      it "returns false for no prefix" do
        expect(described_class.external?("image.jpg")).to be false
      end
    end
  end

  describe ".resolve_path" do
    context "with absolute path" do
      it "returns path unchanged" do
        result = described_class.resolve_path("/assets/image.jpg", "/blog/post")
        expect(result).to eq("/assets/image.jpg")
      end
    end

    context "with relative path starting with ./" do
      it "resolves against base directory" do
        result = described_class.resolve_path("./photo.jpg", "/blog/post")
        expect(result).to eq("/blog/post/photo.jpg")
      end
    end

    context "with relative path (no ./ prefix)" do
      it "resolves against base directory" do
        result = described_class.resolve_path("photo.jpg", "/blog/post")
        expect(result).to eq("/blog/post/photo.jpg")
      end
    end

    context "with parent directory reference" do
      it "resolves ../ correctly" do
        result = described_class.resolve_path("../images/photo.jpg", "/blog/post")
        expect(result).to eq("/blog/images/photo.jpg")
      end
    end

    context "with external URL" do
      it "returns nil" do
        result = described_class.resolve_path("https://example.com/image.jpg", "/blog/post")
        expect(result).to be_nil
      end
    end
  end

  describe ".to_filesystem_path" do
    let(:site_source) { "/home/user/site" }

    context "with absolute site-relative path" do
      it "converts to filesystem path" do
        result = described_class.to_filesystem_path("/assets/image.jpg", site_source)
        expect(result).to eq("/home/user/site/assets/image.jpg")
      end
    end

    context "with leading slash stripped" do
      it "joins correctly" do
        result = described_class.to_filesystem_path("/image.jpg", site_source)
        expect(result).to eq("/home/user/site/image.jpg")
      end
    end

    context "with external URL" do
      it "returns nil" do
        result = described_class.to_filesystem_path("https://example.com/image.jpg", site_source)
        expect(result).to be_nil
      end
    end
  end
end
