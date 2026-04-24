# frozen_string_literal: true

module JekyllAutoThumbnails
  # Configuration parser for auto_thumbnails settings
  #
  # Parses Jekyll site config for auto_thumbnails options and provides
  # accessor methods with appropriate defaults and validation.
  class Configuration
    VALID_PARSERS = %i[html4 html5].freeze

    attr_reader :max_width, :max_height, :quality, :cache_dir, :parser

    # Initialize configuration from Jekyll site
    #
    # @param site [Jekyll::Site] The Jekyll site object
    def initialize(site)
      config_hash = site.config["auto_thumbnails"] || {}

      @enabled = config_hash.fetch("enabled", true)
      @max_width = parse_dimension(config_hash["max_width"])
      @max_height = parse_dimension(config_hash["max_height"])
      @quality = parse_quality(config_hash.fetch("quality", 85))
      @parser = parse_parser(config_hash.fetch("parser", "html5"))
      @cache_dir = File.join(site.source, ".jekyll-cache", "jekyll-auto-thumbnails")
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

    # Parse and validate the HTML parser choice.
    #
    # Accepts "html4" or "html5" (case-insensitive). Raises on any other
    # input so HTML correctness is never silently traded for availability.
    # JRuby cannot use the HTML5 parser (Nokogiri::HTML5 is CRuby-only),
    # so selecting it under JRuby also raises, directing the user to set
    # `auto_thumbnails.parser: html4` explicitly.
    #
    # @param value [Object] parser value from config
    # @return [Symbol] :html4 or :html5
    # @raise [ArgumentError] for invalid values or JRuby + :html5
    def parse_parser(value)
      unless value.is_a?(String)
        raise ArgumentError,
              "auto_thumbnails: parser must be a string (\"html4\" or \"html5\"); got #{value.inspect}"
      end

      symbol = value.downcase.to_sym
      unless VALID_PARSERS.include?(symbol)
        raise ArgumentError,
              "auto_thumbnails: parser must be one of #{VALID_PARSERS.join(", ")}; " \
              "got #{value.inspect}"
      end

      if symbol == :html5 && RUBY_ENGINE == "jruby"
        raise ArgumentError,
              "auto_thumbnails: parser: html5 is not supported on JRuby " \
              "(Nokogiri::HTML5 is CRuby-only). " \
              "Set auto_thumbnails.parser: html4 in _config.yml to run on JRuby."
      end

      symbol
    end
  end
end
