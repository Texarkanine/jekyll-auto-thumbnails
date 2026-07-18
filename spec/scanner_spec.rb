# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::Scanner do
  let(:config) { double("Configuration", max_width: 800, max_height: 600, parser: :html5) }
  let(:registry) { JekyllAutoThumbnails::Registry.new }
  let(:identify_status) { instance_double(Process::Status, success?: true) }

  def stub_identify(file_path, dimensions)
    allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
      .with("-format", "%wx%h", "#{file_path}[0]")
      .and_return(["#{dimensions}\n", identify_status])
  end

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

      it "parses px-suffixed dimension attributes" do
        html = '<article><img src="/photo.jpg" width="300px" height="200px"></article>'
        described_class.scan_html(html, registry, config)

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to eq(200)
      end

      it "ignores images without a src attribute" do
        html = '<article><img width="300" height="200"></article>'
        described_class.scan_html(html, registry, config)
        expect(registry.entries).to be_empty
      end

      it "continues processing after an image without src" do
        html = <<~HTML
          <article>
            <img width="100">
            <img src="/valid.jpg" width="200" height="150">
          </article>
        HTML
        described_class.scan_html(html, registry, config)

        expect(registry.registered?("/valid.jpg")).to be true
        expect(registry.entries.size).to eq(1)
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
        allow(File).to receive(:exist?).with("/site/big-photo.jpg").and_return(true)
        stub_identify("/site/big-photo.jpg", "1200x900")
      end

      it "registers with max dimensions" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/big-photo.jpg")
        expect(reqs[:width]).to eq(800)
        expect(reqs[:height]).to eq(600)
      end

      it "does not register when the image is within max dimensions" do
        stub_identify("/site/big-photo.jpg", "400x300")

        described_class.scan_html(html, registry, config, "/site")
        expect(registry.registered?("/big-photo.jpg")).to be false
      end

      it "does not register when identify fails" do
        failed = instance_double(Process::Status, success?: false)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
          .and_return(["", failed])

        described_class.scan_html(html, registry, config, "/site")
        expect(registry.registered?("/big-photo.jpg")).to be false
      end

      it "does not register when the file is missing" do
        allow(File).to receive(:exist?).with("/site/big-photo.jpg").and_return(false)

        described_class.scan_html(html, registry, config, "/site")
        expect(registry.registered?("/big-photo.jpg")).to be false
      end

      it "skips unsized images when max dimensions are unset" do
        bare_config = double("Configuration", max_width: nil, max_height: nil, parser: :html5)

        described_class.scan_html(html, registry, bare_config, "/site")
        expect(registry.registered?("/big-photo.jpg")).to be false
      end

      it "does not inspect unsized images when max dimensions are unset" do
        bare_config = double("Configuration", max_width: nil, max_height: nil, parser: :html5)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)

        described_class.scan_html(html, registry, bare_config, "/site")

        expect(JekyllAutoThumbnails::ImageMagickWrapper).not_to have_received(:execute_identify)
      end

      it "registers when only max height is configured and image exceeds it" do
        height_only_config = double("Configuration", max_width: nil, max_height: 600, parser: :html5)
        stub_identify("/site/big-photo.jpg", "400x900")

        described_class.scan_html(html, registry, height_only_config, "/site")

        reqs = registry.requirements_for("/big-photo.jpg")
        expect(reqs[:width]).to be_nil
        expect(reqs[:height]).to eq(600)
      end

      it "registers when image exceeds max width but not max height" do
        stub_identify("/site/big-photo.jpg", "1200x500")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/big-photo.jpg")).to be true
      end

      it "registers when image exceeds max height but not max width" do
        stub_identify("/site/big-photo.jpg", "700x900")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/big-photo.jpg")).to be true
      end

      it "does not register when UrlResolver returns nil path" do
        allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
          .with("/big-photo.jpg", "/site")
          .and_return(nil)

        described_class.scan_html(html, registry, config, "/site")
        expect(registry.registered?("/big-photo.jpg")).to be false
      end

      it "registers when only max width is configured and image exceeds it" do
        width_only_config = double("Configuration", max_width: 800, max_height: nil, parser: :html5)
        stub_identify("/site/big-photo.jpg", "1200x500")

        described_class.scan_html(html, registry, width_only_config, "/site")

        reqs = registry.requirements_for("/big-photo.jpg")
        expect(reqs[:width]).to eq(800)
        expect(reqs[:height]).to be_nil
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

      it "continues processing after an external URL" do
        html = <<~HTML
          <article>
            <img src="https://example.com/photo.jpg" width="300">
            <img src="/local.jpg" width="200" height="150">
          </article>
        HTML
        described_class.scan_html(html, registry, config)

        expect(registry.registered?("/local.jpg")).to be true
        expect(registry.entries.size).to eq(1)
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
        allow(File).to receive(:exist?).with("/site/banner.gif").and_return(true)
        # identify is asked for frame [0] only
        stub_identify("/site/banner.gif", "468x90")
      end

      it "uses first frame dimensions only" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/banner.gif")
        expect(reqs[:width]).to eq(312) # Calculated from 60 height with 468:90 ratio
        expect(reqs[:height]).to eq(60)
        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_identify)
          .with("-format", "%wx%h", "/site/banner.gif[0]").at_least(:once)
      end
    end

    context "with width-only explicit dimensions" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" width="300">
          </article>
        HTML
      end

      before do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "600x400")
      end

      it "calculates the missing height from aspect ratio" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to eq(200)
      end
    end

    context "with image dimensions matching original" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" width="300" height="200">
          </article>
        HTML
      end

      before do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "300x200")
      end

      it "does not register (no thumbnail needed)" do
        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/photo.jpg")).to be false
      end

      it "registers when only width matches original dimensions" do
        stub_identify("/site/photo.jpg", "300x250")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/photo.jpg")).to be true
      end

      it "registers when the source file is missing" do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/photo.jpg")).to be true
      end

      it "continues registering subsequent images after one matching original dimensions" do
        html = <<~HTML
          <article>
            <img src="/match.jpg" width="300" height="200">
            <img src="/other.jpg" width="400" height="300">
          </article>
        HTML
        allow(File).to receive(:exist?).with("/site/match.jpg").and_return(true)
        allow(File).to receive(:exist?).with("/site/other.jpg").and_return(true)
        stub_identify("/site/match.jpg", "300x200")
        stub_identify("/site/other.jpg", "800x600")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/match.jpg")).to be false
        expect(registry.registered?("/other.jpg")).to be true
      end
    end

    context "with both width and height explicitly set" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" width="300" height="250">
          </article>
        HTML
      end

      before do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "600x400")
      end

      it "uses HTML dimensions without recalculating from aspect ratio" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to eq(250)
      end

      it "does not calculate missing dimensions when both are specified" do
        stub_identify("/site/photo.jpg", "600x400")

        described_class.scan_html(html, registry, config, "/site")

        expect(JekyllAutoThumbnails::ImageMagickWrapper).to have_received(:execute_identify).once
      end
    end

    context "with height-only explicit dimensions" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" height="200">
          </article>
        HTML
      end

      before do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "600x400")
      end

      it "calculates the missing width from aspect ratio" do
        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to eq(200)
      end
    end

    context "when dimension calculation cannot use the file" do
      let(:html) do
        <<~HTML
          <article>
            <img src="/photo.jpg" width="300">
          </article>
        HTML
      end

      it "registers with the specified width when the file is missing" do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)

        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to be_nil
      end

      it "registers with the specified width when identify returns nil" do
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
          .and_return(["", identify_status])

        described_class.scan_html(html, registry, config, "/site")

        reqs = registry.requirements_for("/photo.jpg")
        expect(reqs[:width]).to eq(300)
        expect(reqs[:height]).to be_nil
      end
    end

    context "with empty or non-numeric dimension attributes" do
      it "treats empty dimension attributes as unsized" do
        html = '<article><img src="/photo.jpg" width="" height=""></article>'
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "1200x900")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/photo.jpg")).to be true
      end

      it "treats non-numeric dimension attributes as unsized" do
        html = '<article><img src="/photo.jpg" width="px" height="px"></article>'
        allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
        stub_identify("/site/photo.jpg", "1200x900")

        described_class.scan_html(html, registry, config, "/site")

        expect(registry.registered?("/photo.jpg")).to be true
      end

      it "treats zero as an explicit width dimension" do
        html = '<article><img src="/zero.jpg" width="0" height="100"></article>'
        described_class.scan_html(html, registry, config)

        expect(registry.registered?("/zero.jpg")).to be true
        expect(registry.requirements_for("/zero.jpg")[:width]).to eq(0)
      end

      it "does not check oversized unsized images without site_source" do
        html = '<article><img src="/big-photo.jpg"></article>'
        allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)

        described_class.scan_html(html, registry, config)

        expect(registry.registered?("/big-photo.jpg")).to be false
        expect(JekyllAutoThumbnails::ImageMagickWrapper).not_to have_received(:execute_identify)
      end
    end

    context "with parser: :html4 (legacy opt-in)" do
      let(:html4_config) { double("Configuration", max_width: 800, max_height: 600, parser: :html4) }
      let(:html) do
        <<~HTML
          <article>
            <img src="/legacy.jpg" width="200" height="150">
          </article>
        HTML
      end

      it "still finds article images under the legacy parser" do
        described_class.scan_html(html, registry, html4_config)
        expect(registry.registered?("/legacy.jpg")).to be true
      end
    end
  end

  describe ".image_dimensions" do
    it "parses width and height from identify output" do
      stub_identify("/img.jpg", "640x480")
      expect(described_class.image_dimensions("/img.jpg")).to eq([640, 480])
    end

    it "parses dimensions without a trailing newline" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .with("-format", "%wx%h", "/img.jpg[0]")
        .and_return(["640x480", identify_status])
      expect(described_class.image_dimensions("/img.jpg")).to eq([640, 480])
    end

    it "returns nil when identify is unsuccessful" do
      failed = instance_double(Process::Status, success?: false)
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["640x480", failed])
      expect(described_class.image_dimensions("/img.jpg")).to be_nil
    end

    it "returns nil when identify output is blank" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["   ", identify_status])
      expect(described_class.image_dimensions("/img.jpg")).to be_nil
    end

    it "returns nil when identify output is whitespace-only with internal newline" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["   \n  ", identify_status])
      expect(described_class.image_dimensions("/img.jpg")).to be_nil
    end

    it "strips leading and trailing whitespace from identify output" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .with("-format", "%wx%h", "/img.jpg[0]")
        .and_return([" 640x480\n", identify_status])
      expect(described_class.image_dimensions("/img.jpg")).to eq([640, 480])
    end

    it "returns nil when identify raises" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_raise(Errno::ENOENT)
      expect(described_class.image_dimensions("/img.jpg")).to be_nil
    end
  end

  describe ".parse_dimension" do
    it "returns nil for nil" do
      expect(described_class.parse_dimension(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(described_class.parse_dimension("")).to be_nil
    end

    it "returns nil for non-numeric values" do
      expect(described_class.parse_dimension("px")).to be_nil
    end

    it "parses integer strings" do
      expect(described_class.parse_dimension("300")).to eq(300)
    end

    it "strips unit suffixes" do
      expect(described_class.parse_dimension("300px")).to eq(300)
    end

    it "extracts all digit groups" do
      expect(described_class.parse_dimension("30px40")).to eq(3040)
    end
  end

  describe ".calculate_dimensions" do
    before do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
    end

    it "returns the specified dimensions when the file is missing" do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)

      expect(described_class.calculate_dimensions("/photo.jpg", 300, nil, "/site"))
        .to eq([300, nil])
    end

    it "returns the specified dimensions when the file is missing even if identify would succeed" do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)
      stub_identify("/site/photo.jpg", "600x400")

      expect(described_class.calculate_dimensions("/photo.jpg", 300, nil, "/site"))
        .to eq([300, nil])
    end

    it "preserves both dimensions when the file is missing" do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)

      expect(described_class.calculate_dimensions("/photo.jpg", 300, 200, "/site"))
        .to eq([300, 200])
    end

    it "returns the specified dimensions when UrlResolver returns nil" do
      allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
        .with("/photo.jpg", "/site")
        .and_return(nil)

      expect(described_class.calculate_dimensions("/photo.jpg", 300, nil, "/site"))
        .to eq([300, nil])
    end

    it "returns the specified dimensions when identify fails" do
      failed = instance_double(Process::Status, success?: false)
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["", failed])

      expect(described_class.calculate_dimensions("/photo.jpg", 300, nil, "/site"))
        .to eq([300, nil])
    end

    it "preserves both dimensions when identify fails" do
      failed = instance_double(Process::Status, success?: false)
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["", failed])

      expect(described_class.calculate_dimensions("/photo.jpg", 300, 200, "/site"))
        .to eq([300, 200])
    end

    it "does not calculate height when identify returns width only" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .with("-format", "%wx%h", "/site/photo.jpg[0]")
        .and_return(["1200\n", identify_status])

      expect(described_class.calculate_dimensions("/photo.jpg", 300, nil, "/site"))
        .to eq([300, nil])
    end

    it "returns unchanged dimensions when both are specified" do
      stub_identify("/site/photo.jpg", "600x400")

      expect(described_class.calculate_dimensions("/photo.jpg", 300, 250, "/site"))
        .to eq([300, 250])
    end

    it "calculates height from width preserving aspect ratio with rounding" do
      stub_identify("/site/photo.jpg", "100x33")

      expect(described_class.calculate_dimensions("/photo.jpg", 10, nil, "/site"))
        .to eq([10, 3])
    end

    it "calculates width from height preserving aspect ratio with rounding" do
      stub_identify("/site/photo.jpg", "468x90")

      expect(described_class.calculate_dimensions("/photo.jpg", nil, 60, "/site"))
        .to eq([312, 60])
    end

    it "rounds calculated width from a non-integer aspect ratio" do
      stub_identify("/site/photo.jpg", "100x33")

      expect(described_class.calculate_dimensions("/photo.jpg", nil, 10, "/site"))
        .to eq([30, 10])
    end

    it "returns nil dimensions unchanged when neither dimension is specified" do
      stub_identify("/site/photo.jpg", "600x400")

      expect(described_class.calculate_dimensions("/photo.jpg", nil, nil, "/site"))
        .to eq([nil, nil])
    end
  end

  describe ".check_and_register_oversized" do
    let(:oversized_config) { double("Configuration", max_width: 800, max_height: 600, parser: :html5) }

    before do
      allow(File).to receive(:exist?).with("/site/big.jpg").and_return(true)
    end

    it "registers when width exceeds max" do
      stub_identify("/site/big.jpg", "1200x500")

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be true
    end

    it "registers when height exceeds max" do
      stub_identify("/site/big.jpg", "700x900")

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be true
    end

    it "does not register when within limits" do
      stub_identify("/site/big.jpg", "400x300")

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "does not register when identify returns no dimensions" do
      failed = instance_double(Process::Status, success?: false)
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["", failed])

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "does not register when UrlResolver returns nil" do
      allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
        .with("/big.jpg", "/site")
        .and_return(nil)

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "does not register when the file is missing even if identify would show oversized" do
      allow(File).to receive(:exist?).with("/site/big.jpg").and_return(false)
      stub_identify("/site/big.jpg", "1200x900")

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "registers max width and height from config" do
      stub_identify("/site/big.jpg", "1200x900")

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      reqs = registry.requirements_for("/big.jpg")
      expect(reqs[:width]).to eq(800)
      expect(reqs[:height]).to eq(600)
    end

    it "does not register when identify returns width only" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .with("-format", "%wx%h", "/site/big.jpg[0]")
        .and_return(["1200\n", identify_status])

      described_class.check_and_register_oversized("/big.jpg", registry, oversized_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "does not register based on height when max height is disabled" do
      disabled_height_config = double("Configuration", max_width: 800, max_height: false, parser: :html5)
      stub_identify("/site/big.jpg", "400x900")

      described_class.check_and_register_oversized("/big.jpg", registry, disabled_height_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end

    it "does not register based on width when max width is disabled" do
      disabled_width_config = double("Configuration", max_width: false, max_height: 600, parser: :html5)
      stub_identify("/site/big.jpg", "1200x400")

      described_class.check_and_register_oversized("/big.jpg", registry, disabled_width_config, "/site")

      expect(registry.registered?("/big.jpg")).to be false
    end
  end

  describe ".dimensions_match_original?" do
    before do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(true)
    end

    it "returns true when dimensions match" do
      stub_identify("/site/photo.jpg", "300x200")

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 200, "/site"))
        .to be true
    end

    it "returns false when width differs" do
      stub_identify("/site/photo.jpg", "300x200")

      expect(described_class.dimensions_match_original?("/photo.jpg", 299, 200, "/site"))
        .to be false
    end

    it "returns false when height differs" do
      stub_identify("/site/photo.jpg", "300x200")

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 199, "/site"))
        .to be false
    end

    it "returns false when the file is missing" do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 200, "/site"))
        .to be false
    end

    it "returns false when the file is missing even if identify would match" do
      allow(File).to receive(:exist?).with("/site/photo.jpg").and_return(false)
      stub_identify("/site/photo.jpg", "300x200")

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 200, "/site"))
        .to be(false)
    end

    it "returns false when UrlResolver returns nil" do
      allow(JekyllAutoThumbnails::UrlResolver).to receive(:to_filesystem_path)
        .with("/photo.jpg", "/site")
        .and_return(nil)

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 200, "/site"))
        .to be false
    end

    it "returns false when identify fails" do
      failed = instance_double(Process::Status, success?: false)
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .and_return(["", failed])

      expect(described_class.dimensions_match_original?("/photo.jpg", 300, 200, "/site"))
        .to be false
    end

    it "returns false when identify returns width only" do
      allow(JekyllAutoThumbnails::ImageMagickWrapper).to receive(:execute_identify)
        .with("-format", "%wx%h", "/site/photo.jpg[0]")
        .and_return(["1200\n", identify_status])

      expect(described_class.dimensions_match_original?("/photo.jpg", 1200, nil, "/site"))
        .to be(false)
    end
  end
end
