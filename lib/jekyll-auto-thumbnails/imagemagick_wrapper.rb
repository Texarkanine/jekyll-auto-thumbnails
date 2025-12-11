# frozen_string_literal: true

require "open3"

module JekyllAutoThumbnails
  # Wrapper for ImageMagick commands supporting both version 6 and 7
  #
  # ImageMagick 6 uses `convert` and `identify` commands directly.
  # ImageMagick 7 uses `magick convert` and `magick identify` (or `magick` with subcommands).
  #
  # This module detects the available version and provides a unified interface.
  module ImageMagickWrapper
    # Check if ImageMagick is available (either version 6 or 7)
    #
    # @return [Boolean] true if ImageMagick is available
    def self.available?
      version = detect_version
      %i[v6 v7].include?(version)
    end

    # Get the convert command array for the detected ImageMagick version
    #
    # @return [Array<String>] command array (e.g., ["convert"] or ["magick", "convert"])
    def self.convert_command
      case detect_version
      when :v7
        %w[magick convert]
      when :v6
        ["convert"]
      else
        ["convert"] # Default fallback (will fail if not available)
      end
    end

    # Get the identify command array for the detected ImageMagick version
    #
    # @return [Array<String>] command array (e.g., ["identify"] or ["magick", "identify"])
    def self.identify_command
      case detect_version
      when :v7
        %w[magick identify]
      when :v6
        ["identify"]
      else
        ["identify"] # Default fallback (will fail if not available)
      end
    end

    # Execute convert command with arguments
    #
    # @param args [Array<String>] arguments to pass to convert
    # @return [Boolean] true if command succeeded
    def self.execute_convert(*args)
      cmd = convert_command + args
      system(*cmd)
    end

    # Execute identify command with arguments
    #
    # @param args [Array<String>] arguments to pass to identify
    # @return [Array<String, Process::Status>] [output, status] tuple
    def self.execute_identify(*args)
      cmd = identify_command + args
      Open3.capture2e(*cmd)
    end

    # Detect which ImageMagick version is available
    #
    # @return [Symbol] :v6, :v7, or :none
    def self.detect_version
      return @detected_version if defined?(@detected_version) && @detected_version

      @detected_version = if command_exists?("magick")
                            :v7
                          elsif command_exists?("convert")
                            :v6
                          else
                            :none
                          end
    end

    # Check if a command exists in PATH
    #
    # @param cmd [String] command name
    # @return [Boolean] true if command found
    def self.command_exists?(cmd)
      cmd_name = Gem.win_platform? ? "#{cmd}.exe" : cmd
      path_dirs = ENV["PATH"].to_s.split(File::PATH_SEPARATOR)

      path_dirs.any? do |dir|
        # Use File.join for cross-platform path construction
        # On Unix, this will use forward slashes even for Windows-style paths in tests
        executable = File.join(dir, cmd_name)
        File.executable?(executable)
      end
    end
  end
end
