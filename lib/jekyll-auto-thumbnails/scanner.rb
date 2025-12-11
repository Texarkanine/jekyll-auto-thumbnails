# frozen_string_literal: true

require "nokogiri"
require "open3"
require_relative "imagemagick_wrapper"

module JekyllAutoThumbnails
  # HTML scanning for images
  module Scanner
    # Scan HTML for images needing optimization
    #
    # @param html [String] HTML content
    # @param registry [Registry] image registry
    # @param config [Configuration] configuration
    # @param site_source [String] Jekyll site source (optional, for unsized image checking)
    def self.scan_html(html, registry, config, site_source = nil)
      doc = Nokogiri::HTML(html)

      # Only process images in <article> tags
      doc.css("article img").each do |img|
        src = img["src"]
        next unless src
        next if UrlResolver.external?(src)

        # Check for explicit dimensions
        width = parse_dimension(img["width"])
        height = parse_dimension(img["height"])

        if width || height
          # Explicitly sized - calculate missing dimension if needed
          if site_source && (width.nil? || height.nil?)
            Jekyll.logger.debug "AutoThumbnails:", "Calculating dimensions for #{src} (#{width}x#{height})"
            width, height = calculate_dimensions(src, width, height, site_source)
            Jekyll.logger.debug "AutoThumbnails:", "Calculated: #{width}x#{height}"
          end

          # Skip if dimensions match original (no thumbnail needed)
          if site_source && dimensions_match_original?(src, width, height, site_source)
            Jekyll.logger.debug "AutoThumbnails:", "Skipping #{src} - dimensions match original"
            next
          end

          Jekyll.logger.debug "AutoThumbnails:", "Registering #{src} at #{width}x#{height}"
          registry.register(src, width, height)
        elsif site_source && (config.max_width || config.max_height)
          # Unsized but max config exists - check actual dimensions
          check_and_register_oversized(src, registry, config, site_source)
        end
      end
    end

    # Check if image exceeds max dimensions and register if so
    #
    # @param url [String] image URL
    # @param registry [Registry] image registry
    # @param config [Configuration] configuration
    # @param site_source [String] site source directory
    def self.check_and_register_oversized(url, registry, config, site_source)
      file_path = UrlResolver.to_filesystem_path(url, site_source)
      return unless file_path && File.exist?(file_path)

      actual_width, actual_height = image_dimensions(file_path)
      return unless actual_width && actual_height

      # Check if exceeds max dimensions
      exceeds_width = config.max_width && actual_width > config.max_width
      exceeds_height = config.max_height && actual_height > config.max_height

      return unless exceeds_width || exceeds_height

      # Register with max dimensions (preserving aspect ratio logic in Generator)
      registry.register(url, config.max_width, config.max_height)
    end

    # Get image dimensions from file
    #
    # @param file_path [String] path to image file
    # @return [Array<Integer, Integer>, nil] [width, height] or nil
    def self.image_dimensions(file_path)
      # Use ImageMagick identify command (shell-free, cross-platform)
      # Use [0] to get only first frame (important for animated GIFs)
      # Wrapper handles both ImageMagick v6 and v7
      output, status = ImageMagickWrapper.execute_identify("-format", "%wx%h", "#{file_path}[0]")
      return nil unless status.success? && !output.strip.empty?

      width, height = output.strip.split("x").map(&:to_i)
      [width, height]
    rescue StandardError
      nil
    end

    # Calculate missing dimension based on aspect ratio
    #
    # @param url [String] image URL
    # @param width [Integer, nil] specified width
    # @param height [Integer, nil] specified height
    # @param site_source [String] site source directory
    # @return [Array<Integer, Integer>] [width, height] with calculated dimension
    def self.calculate_dimensions(url, width, height, site_source)
      file_path = UrlResolver.to_filesystem_path(url, site_source)
      return [width, height] unless file_path && File.exist?(file_path)

      actual_width, actual_height = image_dimensions(file_path)
      return [width, height] unless actual_width && actual_height

      # Calculate missing dimension preserving aspect ratio
      if width && !height
        # Width specified, calculate height
        aspect_ratio = actual_height.to_f / actual_width
        height = (width * aspect_ratio).round
      elsif height && !width
        # Height specified, calculate width
        aspect_ratio = actual_width.to_f / actual_height
        width = (height * aspect_ratio).round
      end

      [width, height]
    end

    # Parse dimension attribute (width or height)
    #
    # @param value [String, nil] attribute value
    # @return [Integer, nil] parsed integer or nil
    def self.parse_dimension(value)
      return nil if value.nil? || value.empty?

      # Strip non-numeric characters (e.g., "300px" -> 300)
      numeric = value.to_s.gsub(/[^\d]/, "")
      return nil if numeric.empty?

      numeric.to_i
    end

    # Check if requested dimensions match original dimensions
    #
    # @param url [String] image URL
    # @param width [Integer] requested width
    # @param height [Integer] requested height
    # @param site_source [String] site source directory
    # @return [Boolean] true if dimensions match original
    def self.dimensions_match_original?(url, width, height, site_source)
      file_path = UrlResolver.to_filesystem_path(url, site_source)
      return false unless file_path && File.exist?(file_path)

      actual_width, actual_height = image_dimensions(file_path)
      return false unless actual_width && actual_height

      width == actual_width && height == actual_height
    end

    private_class_method :check_and_register_oversized, :calculate_dimensions, :parse_dimension,
                         :dimensions_match_original?
  end
end
