# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::ImageMagickWrapper do
  before do
    # Reset memoization between tests
    described_class.instance_variable_set(:@detected_version, nil)
  end

  describe ".available?" do
    context "when ImageMagick 7 (magick) is available" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(true)
        allow(described_class).to receive(:detect_version).and_return(:v7)
      end

      it "returns true" do
        expect(described_class.available?).to be true
      end
    end

    context "when ImageMagick 6 (convert) is available" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(false)
        allow(described_class).to receive(:command_exists?).with("convert").and_return(true)
        allow(described_class).to receive(:detect_version).and_return(:v6)
      end

      it "returns true" do
        expect(described_class.available?).to be true
      end
    end

    context "when ImageMagick is not available" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(false)
        allow(described_class).to receive(:command_exists?).with("convert").and_return(false)
        allow(described_class).to receive(:detect_version).and_return(:none)
      end

      it "returns false" do
        expect(described_class.available?).to be false
      end
    end
  end

  describe ".convert_command" do
    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v7)
      end

      it "returns magick convert command" do
        expect(described_class.convert_command).to eq(%w[magick convert])
      end
    end

    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v6)
      end

      it "returns convert command" do
        expect(described_class.convert_command).to eq(["convert"])
      end
    end
  end

  describe ".identify_command" do
    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v7)
      end

      it "returns magick identify command" do
        expect(described_class.identify_command).to eq(%w[magick identify])
      end
    end

    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v6)
      end

      it "returns identify command" do
        expect(described_class.identify_command).to eq(["identify"])
      end
    end
  end

  describe ".execute_convert" do
    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v7)
        allow(described_class).to receive(:convert_command).and_return(%w[magick convert])
      end

      it "executes magick convert with arguments" do
        expect(described_class).to receive(:system).with("magick", "convert", "input.jpg", "-resize", "300x200",
                                                         "output.jpg")
        described_class.execute_convert("input.jpg", "-resize", "300x200", "output.jpg")
      end
    end

    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v6)
        allow(described_class).to receive(:convert_command).and_return(["convert"])
      end

      it "executes convert with arguments" do
        expect(described_class).to receive(:system).with("convert", "input.jpg", "-resize", "300x200", "output.jpg")
        described_class.execute_convert("input.jpg", "-resize", "300x200", "output.jpg")
      end
    end
  end

  describe ".execute_identify" do
    context "with ImageMagick 7" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v7)
        allow(described_class).to receive(:identify_command).and_return(%w[magick identify])
      end

      it "executes magick identify with arguments" do
        output = "300x200"
        status = double("Status", success?: true)
        expect(Open3).to receive(:capture2e).with("magick", "identify", "-format", "%wx%h", "image.jpg[0]")
                                            .and_return([output, status])
        result = described_class.execute_identify("-format", "%wx%h", "image.jpg[0]")
        expect(result).to eq([output, status])
      end
    end

    context "with ImageMagick 6" do
      before do
        allow(described_class).to receive(:detect_version).and_return(:v6)
        allow(described_class).to receive(:identify_command).and_return(["identify"])
      end

      it "executes identify with arguments" do
        output = "300x200"
        status = double("Status", success?: true)
        expect(Open3).to receive(:capture2e).with("identify", "-format", "%wx%h", "image.jpg[0]")
                                            .and_return([output, status])
        result = described_class.execute_identify("-format", "%wx%h", "image.jpg[0]")
        expect(result).to eq([output, status])
      end
    end
  end

  describe ".detect_version" do
    context "when magick command exists" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(true)
      end

      it "returns :v7" do
        expect(described_class.send(:detect_version)).to eq(:v7)
      end
    end

    context "when convert command exists but magick does not" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(false)
        allow(described_class).to receive(:command_exists?).with("convert").and_return(true)
      end

      it "returns :v6" do
        expect(described_class.send(:detect_version)).to eq(:v6)
      end
    end

    context "when neither command exists" do
      before do
        allow(described_class).to receive(:command_exists?).with("magick").and_return(false)
        allow(described_class).to receive(:command_exists?).with("convert").and_return(false)
      end

      it "returns :none" do
        expect(described_class.send(:detect_version)).to eq(:none)
      end
    end
  end

  describe ".command_exists?" do
    before do
      allow(Gem).to receive(:win_platform?).and_return(false)
      allow(ENV).to receive(:[]).with("PATH").and_return("/usr/bin:/usr/local/bin")
    end

    context "when command found in PATH" do
      it "returns true" do
        allow(File).to receive(:executable?).with("/usr/bin/testcmd").and_return(false)
        allow(File).to receive(:executable?).with("/usr/local/bin/testcmd").and_return(true)
        expect(described_class.send(:command_exists?, "testcmd")).to be true
      end
    end

    context "when command not found in PATH" do
      it "returns false" do
        allow(File).to receive(:executable?).with("/usr/bin/testcmd").and_return(false)
        allow(File).to receive(:executable?).with("/usr/local/bin/testcmd").and_return(false)
        expect(described_class.send(:command_exists?, "testcmd")).to be false
      end
    end

    context "on Windows" do
      before do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(ENV).to receive(:[]).with("PATH").and_return("C:\\Windows;C:\\Program Files")
      end

      it "checks for .exe extension" do
        # File.join on Unix may produce mixed path separators for Windows-style paths
        # Accept any path format since we're Ubuntu-only for development/testing
        allow(File).to receive(:executable?).and_return(false)
        # Stub the path that will actually be constructed (File.join may normalize it)
        # We just need to verify .exe extension is added
        allow(File).to receive(:executable?) do |path|
          path.end_with?("testcmd.exe") && path.include?("Program")
        end
        expect(described_class.send(:command_exists?, "testcmd")).to be true
      end
    end
  end
end
