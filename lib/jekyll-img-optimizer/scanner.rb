# frozen_string_literal: true

module JekyllImgOptimizer
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
          # Explicitly sized - register as-is
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
      # Use ImageMagick identify command
      output = `identify -format "%wx%h" #{Shellwords.escape(file_path)} 2>/dev/null`.strip
      return nil if output.empty?

      width, height = output.split("x").map(&:to_i)
      [width, height]
    rescue StandardError
      nil
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

    private_class_method :check_and_register_oversized, :parse_dimension
  end
end
