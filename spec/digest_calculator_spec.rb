# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllImgOptimizer::DigestCalculator do
  describe ".short_digest" do
    let(:test_file) { File.join(__dir__, "fixtures/images/test.jpg") }

    before do
      # Create test fixture
      FileUtils.mkdir_p(File.dirname(test_file))
      File.write(test_file, "test image content")
    end

    after do
      FileUtils.rm_f(test_file)
    end

    context "with existing file" do
      it "computes 6-character MD5 digest" do
        digest = described_class.short_digest(test_file)

        expect(digest).to be_a(String)
        expect(digest.length).to eq(6)
        expect(digest).to match(/^[0-9a-f]{6}$/)
      end
    end

    context "with same file read twice" do
      it "returns consistent digest" do
        digest1 = described_class.short_digest(test_file)
        digest2 = described_class.short_digest(test_file)

        expect(digest1).to eq(digest2)
      end
    end

    context "with different content" do
      let(:test_file2) { File.join(__dir__, "fixtures/images/test2.jpg") }

      before do
        File.write(test_file2, "different content")
      end

      after do
        FileUtils.rm_f(test_file2)
      end

      it "produces different digests" do
        digest1 = described_class.short_digest(test_file)
        digest2 = described_class.short_digest(test_file2)

        expect(digest1).not_to eq(digest2)
      end
    end

    context "with missing file" do
      it "raises Errno::ENOENT" do
        expect do
          described_class.short_digest("/nonexistent/file.jpg")
        end.to raise_error(Errno::ENOENT)
      end
    end
  end
end
