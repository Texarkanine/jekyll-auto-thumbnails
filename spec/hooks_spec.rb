# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::Hooks do
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

      expect(site.data["auto_thumbnails_config"]).to be_a(JekyllAutoThumbnails::Configuration)
      expect(site.data["auto_thumbnails_registry"]).to be_a(JekyllAutoThumbnails::Registry)
      expect(site.data["auto_thumbnails_generator"]).to be_a(JekyllAutoThumbnails::Generator)
    end

    it "skips when disabled" do
      disabled_site = double("Jekyll::Site",
                             config: { "auto_thumbnails" => { "enabled" => false } },
                             source: "/test/site",
                             data: {})

      described_class.initialize_system(disabled_site)

      expect(disabled_site.data).to be_empty
    end
  end

  describe ".process_site" do
    let(:config) { double("Configuration", enabled?: true, max_width: 800, max_height: 600, cache_dir: "/cache") }
    let(:registry) { JekyllAutoThumbnails::Registry.new }
    let(:generator) { double("Generator") }
    let(:doc1) do
      double("Document",
             output: "<article><img src='/p1.jpg' width='300'></article>",
             path: "_posts/2023-01-01-post.md",
             url: "/posts/post.html")
    end
    let(:doc2) do
      double("Document", output: "<article><img src='/p2.jpg' width='400'></article>", path: "index.md",
                         url: "/index.html")
    end

    before do
      site_data["auto_thumbnails_config"] = config
      site_data["auto_thumbnails_registry"] = registry
      site_data["auto_thumbnails_generator"] = generator

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

    it "builds thumbnail URLs with forward slashes (cross-platform)" do
      registry.register("/assets/img/photo.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/assets/img/photo.jpg", 300, 200)
                                            .and_return("/cache/photo_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      url_map = site.data["auto_thumbnails_url_map"]
      thumb_url = url_map["/assets/img/photo.jpg"]

      # URL must use forward slashes, not backslashes (Windows File.join would use \)
      expect(thumb_url).to eq("/assets/img/photo_thumb-abc123-300x200.jpg")
      expect(thumb_url).not_to include("\\")
    end

    context "with non-HTML documents" do
      let(:css_doc) do
        double("Document", output: "body { color: red; }", path: "assets/style.css", url: "/assets/style.css")
      end
      let(:scss_doc) do
        double("Document", output: "@use 'variables';", path: "assets/main.scss", url: "/assets/main.css")
      end
      let(:js_doc) do
        double("Document", output: "function test() {}", path: "assets/script.js", url: "/assets/script.js")
      end
      let(:html_doc) do
        double("Document", output: "<article><img src='/photo.jpg' width='300'></article>", path: "page.html",
                           url: "/page.html")
      end

      describe ".html_document?" do
        it "returns true for HTML documents" do
          expect(described_class.send(:html_document?, html_doc)).to be true
        end

        it "returns true for markdown documents" do
          md_doc = double("Document", path: "post.md", url: "/post.html")
          expect(described_class.send(:html_document?, md_doc)).to be true
        end

        it "returns false for CSS documents" do
          expect(described_class.send(:html_document?, css_doc)).to be false
        end

        it "returns false for SCSS documents" do
          expect(described_class.send(:html_document?, scss_doc)).to be false
        end

        it "returns false for JS documents" do
          expect(described_class.send(:html_document?, js_doc)).to be false
        end
      end

      it "skips CSS documents" do
        allow(site).to receive(:documents).and_return([css_doc])
        allow(site).to receive(:pages).and_return([])
        allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

        described_class.process_site(site)

        expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
      end

      it "skips SCSS documents" do
        allow(site).to receive(:documents).and_return([scss_doc])
        allow(site).to receive(:pages).and_return([])
        allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

        described_class.process_site(site)

        expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
      end

      it "skips JS documents" do
        allow(site).to receive(:documents).and_return([js_doc])
        allow(site).to receive(:pages).and_return([])
        allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

        described_class.process_site(site)

        expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
      end

      it "processes HTML documents while skipping non-HTML" do
        allow(site).to receive(:documents).and_return([html_doc, css_doc])
        allow(site).to receive(:pages).and_return([scss_doc])
        allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)
        allow(html_doc).to receive(:output=)

        described_class.process_site(site)

        expect(JekyllAutoThumbnails::Scanner).to have_received(:scan_html).with(html_doc.output, registry, config,
                                                                                site.source).once
        expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html).with(css_doc.output, anything, anything,
                                                                                    anything)
        expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html).with(scss_doc.output, anything,
                                                                                    anything, anything)
      end
    end
  end

  describe ".copy_thumbnails" do
    let(:config) { double("Configuration", enabled?: true, cache_dir: "/cache") }
    let(:url_map) { { "/photo.jpg" => "/photo_thumb-abc123-300x200.jpg" } }

    before do
      site_data["auto_thumbnails_config"] = config
      site_data["auto_thumbnails_url_map"] = url_map

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
