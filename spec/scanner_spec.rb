# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllImgOptimizer::Scanner do
  let(:config) { double("Configuration", max_width: 800, max_height: 600) }
  let(:registry) { JekyllImgOptimizer::Registry.new }

  describe ".scan_html" do
    context "with images in article tags" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" width="300" height="200">
            <img src="/photo2.jpg" width="400">
          </article>
        HTML
      end

      it "registers images with dimensions" do
        described_class.scan_html(html, registry, config)

        expect(registry.registered?("/photo.jpg")).to be true
        expect(registry.registered?("/photo2.jpg")).to be true

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to eq(200)
      end
    end

    context "with images outside article tags" do
      let(:html) do
        <<~HTML
          <header>
            <img src="/logo.jpg" width="100">
          </header>
        HTML
      end

      it "does not register them" do
        described_class.scan_html(html, registry, config)
        expect(registry.registered?("/logo.jpg")).to be false
      end
    end

    context "with unsized images and max config" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/big-photo.jpg">
          </article>
        HTML
      end

      before do
        # Mock that image exists and is oversized
        allow(File).to receive(:exist?).with("/site/big-photo.jpg").and_return(true)
        allow(described_class).to receive(:image_dimensions).with("/site/big-photo.jpg")
                                                            .and_return([1200, 900])
      end

      it "registers with max dimensions" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/big-photo.jpg")
        expect(reqs[:width]).to eq(800)
        expect(reqs[:height]).to eq(600)
      end
    end

    context "with external URLs" do
      let(:html) do
        <<~HTML
          <article>
            <img src="https://example.com/photo.jpg" width="300">
          </article>
        HTML
      end

      it "skips them" do
        described_class.scan_html(html, registry, config)
        expect(registry.registered?("https://example.com/photo.jpg")).to be false
      end
    end

    context "with animated GIF (multiple frames)" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/banner.gif" height="60">
          </article>
        HTML
      end

      before do
        # Mock animated GIF with dimensions like: 468x605x511x...
        allow(File).to receive(:exist?).with("/site/banner.gif").and_return(true)
        allow(described_class).to receive(:image_dimensions).with("/site/banner.gif")
                                                            .and_return([468, 60]) # Should parse first frame correctly
      end

      it "uses first frame dimensions only" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/banner.gif")
        expect(reqs[:width]).to eq(468) # Not 468 from wrong parse
        expect(reqs[:height]).to eq(60)
      end
    end
  end
end
