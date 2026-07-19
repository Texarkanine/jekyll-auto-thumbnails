# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllAutoThumbnails::ImageMagickWrapper do
  def reset_detect_version
    described_class.reset_detection_cache!
  end

  def with_path(commands, path: nil, win: false)
    Dir.mktmpdir do |dir|
      Array(commands).each do |name|
        filename = win ? "#{name}.exe" : name
        executable = File.join(dir, filename)
        File.write(executable, "#!/bin/sh\n")
        File.chmod(0o755, executable)
      end

      allow(Gem).to receive(:win_platform?).and_return(win)
      previous_path = ENV.fetch("PATH", nil)
      ENV["PATH"] = path.nil? ? dir : path
      reset_detect_version
      yield dir
    ensure
      ENV["PATH"] = previous_path
      reset_detect_version
    end
  end

  before do
    reset_detect_version
  end

  describe ".detect_version" do
    it "returns :v7 when magick is in PATH" do
      with_path("magick") do
        expect(described_class.detect_version).to eq(:v7)
      end
    end

    it "returns :v6 when convert exists but magick does not" do
      with_path("convert") do
        expect(described_class.detect_version).to eq(:v6)
      end
    end

    it "returns :none when neither command exists" do
      with_path([]) do
        expect(described_class.detect_version).to eq(:none)
      end
    end

    it "memoizes the detected version" do
      with_path("magick") do
        expect(described_class.detect_version).to eq(:v7)

        empty_dir = Dir.mktmpdir
        ENV["PATH"] = empty_dir
        expect(described_class.detect_version).to eq(:v7)
      ensure
        FileUtils.rm_rf(empty_dir) if defined?(empty_dir) && empty_dir
      end
    end

    it "re-probes PATH after reset_detection_cache!" do
      with_path("magick") do
        expect(described_class.detect_version).to eq(:v7)

        empty_dir = Dir.mktmpdir
        ENV["PATH"] = empty_dir
        described_class.reset_detection_cache!

        expect(described_class.detect_version).to eq(:none)
      ensure
        FileUtils.rm_rf(empty_dir) if defined?(empty_dir) && empty_dir
      end
    end

    it "searches every PATH directory" do
      first = Dir.mktmpdir
      second = Dir.mktmpdir
      magick = File.join(second, "magick")
      File.write(magick, "#!/bin/sh\n")
      File.chmod(0o755, magick)

      allow(Gem).to receive(:win_platform?).and_return(false)
      previous_path = ENV.fetch("PATH", nil)
      ENV["PATH"] = [first, second].join(File::PATH_SEPARATOR)

      expect(described_class.detect_version).to eq(:v7)
    ensure
      ENV["PATH"] = previous_path if defined?(previous_path)
      FileUtils.rm_rf(first) if defined?(first) && first
      FileUtils.rm_rf(second) if defined?(second) && second
      reset_detect_version
    end

    it "handles nil PATH" do
      allow(Gem).to receive(:win_platform?).and_return(false)
      previous_path = ENV.fetch("PATH", nil)
      ENV["PATH"] = nil

      expect(described_class.detect_version).to eq(:none)
    ensure
      ENV["PATH"] = previous_path
      reset_detect_version
    end

    context "on Windows" do
      it "checks for .exe extension" do
        with_path("magick", win: true) do
          expect(described_class.detect_version).to eq(:v7)
        end
      end
    end
  end

  describe ".available?" do
    it "returns true when ImageMagick 7 is available" do
      with_path("magick") do
        expect(described_class.available?).to be true
      end
    end

    it "returns true when ImageMagick 6 is available" do
      with_path("convert") do
        expect(described_class.available?).to be true
      end
    end

    it "returns false when ImageMagick is not available" do
      with_path([]) do
        expect(described_class.available?).to be false
      end
    end
  end

  describe ".convert_command" do
    it "returns magick convert for ImageMagick 7" do
      with_path("magick") do
        expect(described_class.convert_command).to eq(%w[magick convert])
      end
    end

    it "returns convert for ImageMagick 6" do
      with_path("convert") do
        expect(described_class.convert_command).to eq(["convert"])
      end
    end

    it "returns convert fallback when ImageMagick is unavailable" do
      with_path([]) do
        expect(described_class.convert_command).to eq(["convert"])
      end
    end
  end

  describe ".identify_command" do
    it "returns magick identify for ImageMagick 7" do
      with_path("magick") do
        expect(described_class.identify_command).to eq(%w[magick identify])
      end
    end

    it "returns identify for ImageMagick 6" do
      with_path("convert") do
        expect(described_class.identify_command).to eq(["identify"])
      end
    end

    it "returns identify fallback when ImageMagick is unavailable" do
      with_path([]) do
        expect(described_class.identify_command).to eq(["identify"])
      end
    end
  end

  describe ".execute_convert" do
    it "executes magick convert with arguments for ImageMagick 7" do
      with_path("magick") do
        expect(described_class).to receive(:system).with("magick", "convert", "input.jpg", "-resize", "300x200",
                                                         "output.jpg")
        described_class.execute_convert("input.jpg", "-resize", "300x200", "output.jpg")
      end
    end

    it "executes convert with arguments for ImageMagick 6" do
      with_path("convert") do
        expect(described_class).to receive(:system).with("convert", "input.jpg", "-resize", "300x200", "output.jpg")
        described_class.execute_convert("input.jpg", "-resize", "300x200", "output.jpg")
      end
    end
  end

  describe ".execute_identify" do
    it "executes magick identify with arguments for ImageMagick 7" do
      with_path("magick") do
        output = "300x200"
        status = double("Status", success?: true)
        expect(Open3).to receive(:capture2e).with("magick", "identify", "-format", "%wx%h", "image.jpg[0]")
                                            .and_return([output, status])
        result = described_class.execute_identify("-format", "%wx%h", "image.jpg[0]")
        expect(result).to eq([output, status])
      end
    end

    it "executes identify with arguments for ImageMagick 6" do
      with_path("convert") do
        output = "300x200"
        status = double("Status", success?: true)
        expect(Open3).to receive(:capture2e).with("identify", "-format", "%wx%h", "image.jpg[0]")
                                            .and_return([output, status])
        result = described_class.execute_identify("-format", "%wx%h", "image.jpg[0]")
        expect(result).to eq([output, status])
      end
    end
  end
end
