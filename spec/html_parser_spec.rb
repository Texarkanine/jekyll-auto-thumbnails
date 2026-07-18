# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::HtmlParser do
  describe ".parse" do
    let(:html) { "<html><body><article><img src='/a.jpg'></article></body></html>" }

    context "with parser: :html5" do
      it "returns a document that can find article images" do
        doc = described_class.parse(html, :html5)
        expect(doc.css("article img").size).to eq(1)
        expect(doc.css("article img").first["src"]).to eq("/a.jpg")
      end

      it "uses Nokogiri::HTML5" do
        doc = described_class.parse(html, :html5)
        expect(doc).to be_a(Nokogiri::HTML5::Document)
      end
    end

    context "with parser: :html4" do
      it "returns a document that can find article images" do
        doc = described_class.parse(html, :html4)
        expect(doc.css("article img").size).to eq(1)
        expect(doc.css("article img").first["src"]).to eq("/a.jpg")
      end

      it "uses the libxml2 HTML parser" do
        doc = described_class.parse(html, :html4)
        expect(doc).to be_a(Nokogiri::HTML4::Document)
      end
    end

    context "with an unknown parser" do
      it "raises ArgumentError naming the unknown parser" do
        expect { described_class.parse(html, :html6) }
          .to raise_error(ArgumentError, /Unknown HTML parser: :html6/)
      end
    end
  end
end
