# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllImgOptimizer::Registry do
  let(:registry) { described_class.new }

  describe "#register" do
    it "stores image with dimensions" do
      registry.register("/assets/photo.jpg", 300, 200)
      expect(registry.registered?("/assets/photo.jpg")).to be true
    end

    it "updates to larger width on duplicate" do
      registry.register("/assets/photo.jpg", 300, 200)
      registry.register("/assets/photo.jpg", 400, 200)
      
      reqs = registry.requirements_for("/assets/photo.jpg")
      expect(reqs[:width]).to eq(400)
      expect(reqs[:height]).to eq(200)
    end

    it "updates to larger height on duplicate" do
      registry.register("/assets/photo.jpg", 300, 200)
      registry.register("/assets/photo.jpg", 300, 300)
      
      reqs = registry.requirements_for("/assets/photo.jpg")
      expect(reqs[:width]).to eq(300)
      expect(reqs[:height]).to eq(300)
    end

    it "handles nil dimensions" do
      registry.register("/assets/photo.jpg", nil, 400)
      reqs = registry.requirements_for("/assets/photo.jpg")
      expect(reqs[:width]).to be_nil
      expect(reqs[:height]).to eq(400)
    end
  end

  describe "#entries" do
    it "returns all registered images" do
      registry.register("/photo1.jpg", 300, 200)
      registry.register("/photo2.jpg", 400, 300)
      
      entries = registry.entries
      expect(entries.size).to eq(2)
      expect(entries).to have_key("/photo1.jpg")
      expect(entries).to have_key("/photo2.jpg")
    end
  end

  describe "#registered?" do
    it "returns true for registered image" do
      registry.register("/photo.jpg", 300, 200)
      expect(registry.registered?("/photo.jpg")).to be true
    end

    it "returns false for unregistered image" do
      expect(registry.registered?("/photo.jpg")).to be false
    end
  end

  describe "#requirements_for" do
    it "returns requirements hash" do
      registry.register("/photo.jpg", 300, 200)
      reqs = registry.requirements_for("/photo.jpg")
      
      expect(reqs).to be_a(Hash)
      expect(reqs[:width]).to eq(300)
      expect(reqs[:height]).to eq(200)
    end

    it "returns nil for unregistered image" do
      expect(registry.requirements_for("/photo.jpg")).to be_nil
    end
  end
end

