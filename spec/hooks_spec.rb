# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::Hooks do
  let(:logger) { double("logger", info: nil, warn: nil, debug: nil) }
  let(:site_data) { {} }
  let(:site) do
    double("Jekyll::Site",
           config: {},
           source: "/test/site",
           dest: "/test/_site",
           data: site_data)
  end

  before do
    allow(Jekyll).to receive(:logger).and_return(logger)
  end

  describe ".initialize_system" do
    it "creates configuration, registry, and generator" do
      described_class.initialize_system(site)

      expect(site.data["auto_thumbnails_config"]).to be_a(JekyllAutoThumbnails::Configuration)
      expect(site.data["auto_thumbnails_registry"]).to be_a(JekyllAutoThumbnails::Registry)
      expect(site.data["auto_thumbnails_generator"]).to be_a(JekyllAutoThumbnails::Generator)
    end

    it "passes site.source to the generator" do
      expect(JekyllAutoThumbnails::Generator).to receive(:new)
        .with(an_instance_of(JekyllAutoThumbnails::Configuration), "/test/site")
        .and_call_original

      described_class.initialize_system(site)
    end

    it "logs that the system initialized" do
      described_class.initialize_system(site)

      expect(logger).to have_received(:info).with("AutoThumbnails:", "System initialized")
    end

    it "skips when disabled" do
      disabled_site = double("Jekyll::Site",
                             config: { "auto_thumbnails" => { "enabled" => false } },
                             source: "/test/site",
                             data: {})

      described_class.initialize_system(disabled_site)

      expect(disabled_site.data).to be_empty
      expect(logger).not_to have_received(:info)
    end
  end

  describe ".html_document?" do
    def doc_with(path: nil, url: nil)
      double("Document", path: path, url: url)
    end

    it "returns true for .html, .htm, .md, and .markdown paths" do
      expect(described_class.html_document?(doc_with(path: "page.html"))).to be true
      expect(described_class.html_document?(doc_with(path: "page.htm"))).to be true
      expect(described_class.html_document?(doc_with(path: "_posts/post.md"))).to be true
      expect(described_class.html_document?(doc_with(path: "readme.markdown"))).to be true
    end

    it "matches extensions case-insensitively" do
      expect(described_class.html_document?(doc_with(path: "page.HTML"))).to be true
      expect(described_class.html_document?(doc_with(path: "post.MD"))).to be true
    end

    it "prefers path over url when path is present" do
      expect(described_class.html_document?(doc_with(path: "style.css", url: "/index.html"))).to be false
    end

    it "falls back to url when path is nil" do
      expect(described_class.html_document?(doc_with(path: nil, url: "/about.html"))).to be true
    end

    it "returns false when neither path nor url has a recognized extension" do
      expect(described_class.html_document?(doc_with(path: nil, url: nil))).to be false
      expect(described_class.html_document?(doc_with(path: "assets/app.js", url: "/assets/app.js"))).to be false
    end
  end

  describe ".process_site" do
    let(:config) do
      double("Configuration",
             enabled?: true, max_width: 800, max_height: 600, cache_dir: "/cache", parser: :html5)
    end
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
      allow(site).to receive(:documents).and_return([doc1])
      allow(site).to receive(:pages).and_return([])
      registry.register("/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/p1.jpg", 300, 200)
                                            .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(generator).to have_received(:generate).with("/p1.jpg", 300, 200).at_least(:once)
      expect(doc1).to have_received(:output=)
    end

    it "builds thumbnail URLs with forward slashes (cross-platform)" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("/assets/img/photo.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/assets/img/photo.jpg", 300, 200)
                                            .and_return("/cache/photo_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      url_map = site.data["auto_thumbnails_url_map"]
      thumb_url = url_map["/assets/img/photo.jpg"]

      expect(thumb_url).to eq("/assets/img/photo_thumb-abc123-300x200.jpg")
      expect(thumb_url).not_to include("\\")
    end

    it "builds root-level thumbnail URLs without a directory prefix" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("photo.jpg", 300, 200)
      allow(generator).to receive(:generate).with("photo.jpg", 300, 200)
                                            .and_return("/cache/photo_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(site.data["auto_thumbnails_url_map"]["photo.jpg"]).to eq("/photo_thumb-abc123-300x200.jpg")
    end

    it "stores the url_map on site.data" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("/assets/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/assets/p1.jpg", 300, 200)
                                            .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(site.data["auto_thumbnails_url_map"]).to eq(
        "/assets/p1.jpg" => "/assets/p1_thumb-abc123-300x200.jpg"
      )
    end

    it "logs how many images were found" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("/p1.jpg", 300, 200)

      described_class.process_site(site)

      expect(logger).to have_received(:info).with("AutoThumbnails:", "Found 1 images to optimize")
    end

    it "logs how many thumbnails were generated" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/p1.jpg", 300, 200)
                                            .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(logger).to have_received(:info).with("AutoThumbnails:", "Generated 1 thumbnails")
    end

    it "warns and omits failed thumbnails from the url_map" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      registry.register("/fail.jpg", 100, 100)
      allow(generator).to receive(:generate).with("/fail.jpg", 100, 100).and_return(nil)

      described_class.process_site(site)

      expect(logger).to have_received(:warn).with("AutoThumbnails:", "Failed to generate thumbnail for /fail.jpg")
      expect(site.data["auto_thumbnails_url_map"]).not_to have_key("/fail.jpg")
    end

    it "skips when config is missing" do
      site_data.delete("auto_thumbnails_config")
      allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

      described_class.process_site(site)

      expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
    end

    it "skips when config is disabled" do
      allow(config).to receive(:enabled?).and_return(false)
      allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

      described_class.process_site(site)

      expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
    end

    it "skips when ImageMagick is unavailable" do
      allow(generator).to receive(:imagemagick_available?).and_return(false)
      allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

      described_class.process_site(site)

      expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html)
      expect(logger).to have_received(:warn).with("AutoThumbnails:", "ImageMagick not found - skipping")
    end

    it "skips documents without rendered output" do
      allow(doc1).to receive(:output).and_return(nil)
      allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)

      described_class.process_site(site)

      expect(JekyllAutoThumbnails::Scanner).not_to have_received(:scan_html).with(nil, anything, anything, anything)
      expect(doc1).not_to have_received(:output=)
    end

    it "processes pages when there are no documents" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([doc2])
      allow(generator).to receive(:generate).and_return("/cache/thumb.jpg")

      described_class.process_site(site)

      expect(registry.registered?("/p2.jpg")).to be true
    end

    it "continues scanning after a document without output" do
      blank_doc = double("Document", output: nil, path: "draft.html", url: "/draft.html")
      html_doc = double(
        "Document",
        output: "<article><img src='/scan-later.jpg' width='200'></article>",
        path: "page.html",
        url: "/page.html"
      )
      allow(site).to receive(:documents).and_return([blank_doc, html_doc])
      allow(site).to receive(:pages).and_return([])
      allow(html_doc).to receive(:output=)
      allow(generator).to receive(:generate).and_return("/cache/scan_later_thumb.jpg")

      described_class.process_site(site)

      expect(registry.registered?("/scan-later.jpg")).to be true
    end

    it "still rewrites HTML pages after a non-HTML page in the rewrite pass" do
      css_doc = double("Document", output: "body {}", path: "assets/style.css", url: "/assets/style.css")
      html_doc = double(
        "Document",
        output: "<article><img src='/rewrite.jpg' width='200'></article>",
        path: "page.html",
        url: "/page.html"
      )
      allow(site).to receive(:documents).and_return([css_doc, html_doc])
      allow(site).to receive(:pages).and_return([])
      allow(html_doc).to receive(:output=)
      allow(JekyllAutoThumbnails::Scanner).to receive(:scan_html)
      registry.register("/rewrite.jpg", 200, 200)
      allow(generator).to receive(:generate).with("/rewrite.jpg", 200, 200)
                                            .and_return("/cache/rewrite_thumb.jpg")

      described_class.process_site(site)

      expect(html_doc).to have_received(:output=)
    end

    it "continues scanning after a non-HTML document" do
      css_doc = double("Document", output: "body {}", path: "assets/style.css", url: "/assets/style.css")
      html_doc = double(
        "Document",
        output: "<article><img src='/later.jpg' width='200'></article>",
        path: "page.html",
        url: "/page.html"
      )
      allow(site).to receive(:documents).and_return([css_doc, html_doc])
      allow(site).to receive(:pages).and_return([])
      allow(html_doc).to receive(:output=)
      allow(generator).to receive(:generate).and_return("/cache/later_thumb.jpg")

      described_class.process_site(site)

      expect(registry.registered?("/later.jpg")).to be true
    end

    it "still rewrites later documents when an earlier document has no output" do
      blank_doc = double("Document", output: nil, path: "draft.html", url: "/draft.html")
      allow(site).to receive(:documents).and_return([blank_doc, doc1])
      allow(site).to receive(:pages).and_return([])
      registry.register("/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/p1.jpg", 300, 200)
                                            .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(doc1).to have_received(:output=)
    end

    it "passes nil dimensions when registry entries omit width" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      allow(registry).to receive(:entries).and_return("/partial.jpg" => { height: 200 })
      allow(generator).to receive(:generate)

      described_class.process_site(site)

      expect(generator).to have_received(:generate).with("/partial.jpg", nil, 200)
    end

    it "requires registry and generator keys to be present in site.data" do
      site_data.delete("auto_thumbnails_registry")

      expect { described_class.process_site(site) }.to raise_error(NoMethodError)
    end

    it "requires the generator to be present in site.data" do
      site_data.delete("auto_thumbnails_generator")

      expect { described_class.process_site(site) }.to raise_error(NoMethodError)
    end

    it "passes nil height when registry entries omit height" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([])
      allow(registry).to receive(:entries).and_return("/partial.jpg" => { width: 300 })
      allow(generator).to receive(:generate)

      described_class.process_site(site)

      expect(generator).to have_received(:generate).with("/partial.jpg", 300, nil)
    end

    it "rewrites URLs in pages" do
      allow(site).to receive(:documents).and_return([])
      allow(site).to receive(:pages).and_return([doc2])
      registry.register("/p2.jpg", 400, 300)
      allow(generator).to receive(:generate).with("/p2.jpg", 400, 300)
                                            .and_return("/cache/p2_thumb-abc123-400x300.jpg")

      described_class.process_site(site)

      expect(doc2).to have_received(:output=)
    end

    it "passes config.parser to replace_urls during the rewrite pass" do
      html4_config = double("Configuration",
                            enabled?: true, max_width: 800, max_height: 600, cache_dir: "/cache", parser: :html4)
      site_data["auto_thumbnails_config"] = html4_config
      html_doc = double(
        "Document",
        output: "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
                "<body><article><img src='/p1.jpg' width='300'></article></body></html>",
        path: "page.html",
        url: "/page.html"
      )
      allow(site).to receive(:documents).and_return([html_doc])
      allow(site).to receive(:pages).and_return([])
      allow(html_doc).to receive(:output=)
      registry.register("/p1.jpg", 300, 200)
      allow(generator).to receive(:generate).with("/p1.jpg", 300, 200)
                                            .and_return("/cache/p1_thumb-abc123-300x200.jpg")

      described_class.process_site(site)

      expect(html_doc).to have_received(:output=) do |html|
        expect(html).to match(/meta\s+http-equiv=["']Content-Type["']/i)
      end
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

  describe ".replace_urls" do
    context "with an empty url_map" do
      let(:html) { "<article><img src='/a.jpg'></article>" }

      it "returns the input unchanged (no parse, no serialization)" do
        expect(JekyllAutoThumbnails::HtmlParser).not_to receive(:parse)

        expect(described_class.replace_urls(html, {})).to equal(html)
      end
    end

    context "with no <img in the document" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><p>hi</p></body></html>"
      end

      it "short-circuits before parsing and returns the input unchanged" do
        expect(JekyllAutoThumbnails::HtmlParser).not_to receive(:parse)

        expect(described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })).to equal(html)
      end
    end

    context "when url_map has no matching src" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><article><img src='/a.jpg'></article></body></html>"
      end

      it "returns the input unchanged (identity, no re-serialization)" do
        expect(described_class.replace_urls(html, { "/other.jpg" => "/other_thumb.jpg" })).to equal(html)
      end
    end

    context "when the only matching <img> is outside <article>" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><header><img src='/logo.jpg'></header></body></html>"
      end

      it "returns the input unchanged (non-article images are not rewritten)" do
        expect(described_class.replace_urls(html, { "/logo.jpg" => "/logo_thumb.jpg" })).to equal(html)
      end
    end

    context "when an <img> has no src attribute" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><article><img width='100'></article></body></html>"
      end

      it "returns the input unchanged" do
        expect(described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })).to equal(html)
      end
    end

    context "when an empty src precedes a matching src in the same article" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><article><img src=''><img src='/a.jpg'></article></body></html>"
      end

      it "still rewrites the later matching image" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out).to include("/a_thumb.jpg")
      end
    end

    context "when a non-matching src precedes a matching src in the same article" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><article><img src='/miss.jpg'><img src='/a.jpg'></article></body></html>"
      end

      it "still rewrites the later matching image" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out).to include("/a_thumb.jpg")
      end
    end

    context "with an uppercase <IMG> tag" do
      let(:html) do
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>" \
          "<body><article><IMG SRC='/a.jpg'></article></body></html>"
      end

      it "does not short-circuit; rewrites the src after parse" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out).to include("/a_thumb.jpg")
      end
    end

    context "with parser: :html5 (default) and a real replacement" do
      let(:html) do
        "<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>" \
          "<title>t</title></head><body><article><img src='/a.jpg'></article></body></html>"
      end

      it "rewrites <article><img src>" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out).to include("/a_thumb.jpg")
        expect(out).not_to include("src=\"/a.jpg\"")
        expect(out).not_to include("src='/a.jpg'")
      end

      it "does NOT inject <meta http-equiv=\"Content-Type\"> under the default parser" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out).not_to match(/meta\s+http-equiv=["']Content-Type["']/i)
        expect(out).to include("/a_thumb.jpg")
      end

      it "preserves the single <meta charset=\"utf-8\">" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" })
        expect(out.scan(/<meta[^>]*charset/i).size).to eq(1)
      end
    end

    context "with parser: :html4 (legacy opt-in) and a real replacement" do
      let(:html) do
        "<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'>" \
          "<title>t</title></head><body><article><img src='/a.jpg'></article></body></html>"
      end

      it "rewrites <article><img src>" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" }, parser: :html4)
        expect(out).to include("/a_thumb.jpg")
      end

      it "preserves the legacy behavior of injecting <meta http-equiv> on serialize" do
        out = described_class.replace_urls(html, { "/a.jpg" => "/a_thumb.jpg" }, parser: :html4)
        expect(out).to match(/meta\s+http-equiv=["']Content-Type["']/i)
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

    it "creates destination directories before copying" do
      described_class.copy_thumbnails(site)

      expect(FileUtils).to have_received(:mkdir_p).with("/test/_site")
    end

    it "preserves nested URL directory structure" do
      nested_map = { "/assets/img/photo.jpg" => "/assets/img/photo_thumb-abc123-300x200.jpg" }
      site_data["auto_thumbnails_url_map"] = nested_map

      described_class.copy_thumbnails(site)

      expect(FileUtils).to have_received(:mkdir_p).with("/test/_site/assets/img")
      expect(FileUtils).to have_received(:cp).with(
        "/cache/photo_thumb-abc123-300x200.jpg",
        "/test/_site/assets/img/photo_thumb-abc123-300x200.jpg"
      )
    end

    it "logs copy start and completion" do
      described_class.copy_thumbnails(site)

      expect(logger).to have_received(:info).with("AutoThumbnails:", "Copying 1 thumbnails to _site")
      expect(logger).to have_received(:info).with("AutoThumbnails:", "All thumbnails copied")
    end

    it "skips when config is disabled" do
      allow(config).to receive(:enabled?).and_return(false)

      described_class.copy_thumbnails(site)

      expect(FileUtils).not_to have_received(:cp)
      expect(logger).not_to have_received(:info)
    end

    it "skips when config is missing" do
      site_data.delete("auto_thumbnails_config")

      described_class.copy_thumbnails(site)

      expect(FileUtils).not_to have_received(:cp)
    end

    it "skips when url_map is missing" do
      site_data.delete("auto_thumbnails_url_map")

      described_class.copy_thumbnails(site)

      expect(FileUtils).not_to have_received(:cp)
    end

    it "skips when url_map is empty" do
      site_data["auto_thumbnails_url_map"] = {}

      described_class.copy_thumbnails(site)

      expect(FileUtils).not_to have_received(:cp)
      expect(logger).not_to have_received(:info)
    end
  end
end
