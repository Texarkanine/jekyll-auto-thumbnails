# frozen_string_literal: true

module JekyllImgOptimizer
  # Configuration parser for img_optimizer settings
  #
  # Parses Jekyll site config for img_optimizer options and provides
  # accessor methods with appropriate defaults and validation.
  class Configuration
    attr_reader :max_width, :max_height, :quality, :cache_dir

    # Initialize configuration from Jekyll site
    #
    # @param site [Jekyll::Site] The Jekyll site object
    def initialize(site)
      config_hash = site.config["img_optimizer"] || {}

      @enabled = config_hash.fetch("enabled", true)
      @max_width = parse_dimension(config_hash["max_width"])
      @max_height = parse_dimension(config_hash["max_height"])
      @quality = parse_quality(config_hash.fetch("quality", 85))
      @cache_dir = File.join(site.source, ".jekyll-cache", "jekyll-img-optimizer")
    end

    # Check if image optimization is enabled
    #
    # @return [Boolean] true if enabled (default: true)
    def enabled?
      @enabled
    end

    private

    # Parse dimension value (max_width or max_height)
    #
    # @param value [Object] dimension value from config
    # @return [Integer, nil] positive integer or nil
    def parse_dimension(value)
      val = value.to_i
      val.positive? ? val : nil
    end

    # Parse quality value (0-100)
    #
    # @param value [Object] quality value from config
    # @return [Integer] quality value 0-100, or 85 if invalid
    def parse_quality(value)
      val = value.to_i
      val.between?(0, 100) ? val : 85
    end
  end
end

