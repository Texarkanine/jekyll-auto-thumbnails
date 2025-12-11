# frozen_string_literal: true

require "fileutils"

module JekyllAutoThumbnails
  # Thumbnail generation via ImageMagick
  class Generator
    # Initialize generator
    #
    # @param config [Configuration] configuration
    # @param site_source [String] Jekyll site source directory
    def initialize(config, site_source)
      @config = config
      @site_source = site_source
    end

    # Check if ImageMagick is available (cross-platform)
    #
    # @return [Boolean] true if convert command found in PATH
    def imagemagick_available?
      cmd_name = Gem.win_platform? ? "convert.exe" : "convert"
      path_dirs = ENV["PATH"].to_s.split(File::PATH_SEPARATOR)

      path_dirs.any? do |dir|
        executable = File.join(dir, cmd_name)
        File.executable?(executable)
      end
    end

    # Generate thumbnail (with caching)
    #
    # @param url [String] image URL
    # @param width [Integer, nil] target width
    # @param height [Integer, nil] target height
    # @return [String, nil] path to cached thumbnail or nil if failed
    def generate(url, width, height)
      # Resolve source file
      source_path = UrlResolver.to_filesystem_path(url, @site_source)
      return nil unless source_path && File.exist?(source_path)

      # Compute digest
      digest = DigestCalculator.short_digest(source_path)

      # Build thumbnail filename
      basename = File.basename(source_path, File.extname(source_path))
      ext = File.extname(source_path)
      thumb_filename = build_thumbnail_filename(basename, digest, width, height, ext)

      # Check cache
      cached_path = File.join(@config.cache_dir, thumb_filename)
      return cached_path if File.exist?(cached_path)

      # Generate
      FileUtils.mkdir_p(@config.cache_dir)
      success = shell_generate(source_path, cached_path, width, height)

      return nil unless success

      # Check if thumbnail is larger than original
      if File.size(cached_path) > File.size(source_path)
        Jekyll.logger.warn "AutoThumbnails:",
                           "Thumbnail larger than original (#{File.size(cached_path)} > #{File.size(source_path)}), " \
                           "deleting #{cached_path}"
        FileUtils.rm_f(cached_path)
        return nil
      end

      cached_path
    end

    # Build thumbnail filename
    #
    # @param basename [String] image basename (no extension)
    # @param digest [String] 6-char MD5 digest
    # @param width [Integer, nil] width
    # @param height [Integer, nil] height
    # @param ext [String] file extension
    # @return [String] thumbnail filename
    def build_thumbnail_filename(basename, digest, width, height, ext)
      width_str = width || ""
      height_str = height || ""
      "#{basename}_thumb-#{digest}-#{width_str}x#{height_str}#{ext}"
    end

    private

    # Generate thumbnail using ImageMagick
    #
    # @param source_path [String] source image path
    # @param dest_path [String] destination thumbnail path
    # @param width [Integer, nil] target width
    # @param height [Integer, nil] target height
    # @return [Boolean] true if successful
    def shell_generate(source_path, dest_path, width, height)
      geometry = build_geometry(width, height)
      ext = File.extname(source_path)

      # Build command array (no shell interpretation)
      cmd = ["convert", source_path, "-resize", geometry]

      # Add quality for lossy formats
      if quality_needed?(ext)
        cmd << "-quality"
        cmd << @config.quality.to_s
      end

      cmd << dest_path

      # Call system with array (bypasses shell)
      system(*cmd)
    end

    # Build ImageMagick geometry string
    #
    # @param width [Integer, nil] target width
    # @param height [Integer, nil] target height
    # @return [String] geometry string (e.g., "400x300>")
    def build_geometry(width, height)
      width_str = width || ""
      height_str = height || ""
      "#{width_str}x#{height_str}>"
    end

    # Check if quality parameter needed for image format
    #
    # @param ext [String] file extension
    # @return [Boolean] true if quality parameter should be used
    def quality_needed?(ext)
      %w[.jpg .jpeg].include?(ext.downcase)
    end
  end
end
