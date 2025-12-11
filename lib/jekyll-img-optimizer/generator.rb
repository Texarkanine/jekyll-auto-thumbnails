# frozen_string_literal: true

require "fileutils"
require "shellwords"

module JekyllImgOptimizer
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

    # Check if ImageMagick is available
    #
    # @return [Boolean] true if convert command found
    def imagemagick_available?
      system("which convert > /dev/null 2>&1")
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

      success ? cached_path : nil
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
      quality = quality_param(ext)

      cmd_parts = [
        "convert",
        Shellwords.escape(source_path),
        "-resize",
        Shellwords.escape(geometry)
      ]
      cmd_parts << quality if quality
      cmd_parts << Shellwords.escape(dest_path)

      system(cmd_parts.join(" "))
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

    # Get quality parameter for image format
    #
    # @param ext [String] file extension
    # @return [String, nil] quality parameter or nil for lossless
    def quality_param(ext)
      case ext.downcase
      when ".jpg", ".jpeg"
        "-quality #{@config.quality}"
      else
        nil
      end
    end
  end
end
