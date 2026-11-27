# frozen_string_literal: true

require_relative "html_parser"

module JekyllAutoThumbnails
  # Jekyll hook integration
  module Hooks
    # Format a duration for Jekyll log suffixes.
    #
    # @param seconds [Numeric] elapsed seconds
    # @return [String] `in Xs` under a minute, otherwise `in X m Y s`
    def self.format_elapsed(seconds)
      total = seconds.round
      return "in #{total}s" if total < 60

      minutes, remainder = total.divmod(60)
      "in #{minutes} m #{remainder} s"
    end

    # Initialize optimization system
    #
    # @param site [Jekyll::Site] Jekyll site
    def self.initialize_system(site)
      config = Configuration.new(site)
      return unless config.enabled?

      site.data["auto_thumbnails_config"] = config
      site.data["auto_thumbnails_registry"] = Registry.new
      site.data["auto_thumbnails_generator"] = Generator.new(config, site.source)

      Jekyll.logger.info "AutoThumbnails:", "System initialized"
    end

    # Process site - scan, generate, replace
    #
    # @param site [Jekyll::Site] Jekyll site
    def self.process_site(site)
      config = site.data["auto_thumbnails_config"]
      return unless config&.enabled?

      registry = site.data["auto_thumbnails_registry"]
      generator = site.data["auto_thumbnails_generator"]

      # Check ImageMagick
      unless generator.imagemagick_available?
        Jekyll.logger.warn "AutoThumbnails:", "ImageMagick not found - skipping"
        return
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Scan all documents and pages. Measurements are file pixels, not thumbnail requests.
      measurements = {}
      (site.documents + site.pages).each do |doc|
        next unless doc.output
        next unless html_document?(doc)

        measurements.merge!(Scanner.scan_html(doc.output, registry, config, site.source))
      end

      Jekyll.logger.info "AutoThumbnails:", "Found #{registry.entries.size} images to optimize"

      # Generate thumbnails. A served size is the thumbnail file when src changes,
      # and the measured file when it does not.
      url_map = {}
      served = {}
      registry.entries.each do |url, requirements|
        cached_path = generator.generate(url, requirements[:width], requirements[:height])

        if cached_path
          # Build thumbnail URL (use forward slashes for URLs, not File.join)
          thumb_filename = File.basename(cached_path)
          url_dir = File.dirname(url)
          # Ensure URL uses forward slashes (cross-platform URLs)
          thumb_url = if url_dir == "."
                        "/#{thumb_filename}"
                      else
                        "#{url_dir}/#{thumb_filename}"
                      end
          url_map[url] = thumb_url
          width, height = Scanner.image_dimensions(cached_path)
          served[url] = { width: width, height: height } if width && height
        else
          Jekyll.logger.warn "AutoThumbnails:", "Failed to generate thumbnail for #{url}"
        end
      end

      measurements.each do |url, dims|
        next if url_map.key?(url)

        served[url] = dims
      end

      # Store url_map for post_write hook
      site.data["auto_thumbnails_url_map"] = url_map

      # Replace URLs in HTML
      (site.documents + site.pages).each do |doc|
        next unless doc.output
        next unless html_document?(doc)

        doc.output = replace_urls(doc.output, url_map, parser: config.parser, sizes: served)
      end

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      Jekyll.logger.info "AutoThumbnails:", "Generated #{url_map.size} thumbnails #{format_elapsed(elapsed)}"
    end

    # Copy thumbnails from cache to _site
    #
    # @param site [Jekyll::Site] Jekyll site
    def self.copy_thumbnails(site)
      config = site.data["auto_thumbnails_config"]
      return unless config&.enabled?

      url_map = site.data["auto_thumbnails_url_map"]
      return unless url_map && !url_map.empty?

      Jekyll.logger.info "AutoThumbnails:", "Copying #{url_map.size} thumbnails to _site"

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      url_map.each_value do |thumb_url|
        thumb_filename = File.basename(thumb_url)
        cached_path = File.join(config.cache_dir, thumb_filename)

        # Build destination path in _site preserving directory structure
        dest_path = File.join(site.dest, thumb_url)
        dest_dir = File.dirname(dest_path)

        FileUtils.mkdir_p(dest_dir)
        FileUtils.cp(cached_path, dest_path)
      end

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      Jekyll.logger.info "AutoThumbnails:", "All thumbnails copied #{format_elapsed(elapsed)}"
    end

    # Replace image URLs in HTML.
    #
    # Returns the input string unchanged (object identity) when no article image
    # changes. A change is a new thumbnail `src`, or a `width` and `height`
    # taken from `sizes`. This is both a perf win for pages with no matching
    # images and a correctness win: the HTML4 path otherwise round-trips every
    # page through libxml2's serializer, which injects a spurious
    # `<meta http-equiv="Content-Type">` on HTML5 sites.
    #
    # A rewritten page also gets {ARTICLE_IMAGE_HEIGHT_RULE} at the start of
    # `head`. Width and height attributes reserve the ratio and act as a fixed
    # CSS height. `:where()` has zero specificity, so the rule beats that
    # height and loses to any author rule that sets one. Unchanged pages do
    # not get the tag.
    #
    # @param html [String] HTML content
    # @param url_map [Hash] original URL => thumbnail URL
    # @param parser [Symbol] :html5 (default) or :html4
    # @param sizes [Hash] original URL => {width:, height:} for the file the browser will load
    # @return [String] modified HTML (or the input itself, unchanged)
    def self.replace_urls(html, url_map, parser: :html5, sizes: {})
      return html if url_map.empty? && sizes.empty?
      return html unless html.match?(/<img/i)

      doc = HtmlParser.parse(html, parser)

      modified = false
      doc.css("article img").each do |img|
        src = img["src"]
        next unless src

        if (thumb_url = url_map[src]) && img["src"] != thumb_url
          img["src"] = thumb_url
          modified = true
        end

        size = sizes[src]
        next unless size && size[:width] && size[:height]

        width = size[:width].to_s
        height = size[:height].to_s
        if img["width"] != width
          img["width"] = width
          modified = true
        end
        if img["height"] != height
          img["height"] = height
          modified = true
        end
      end

      return html unless modified

      release_article_image_height(doc)
      doc.to_html
    end

    # Zero-specificity height release for article images. See {replace_urls}.
    ARTICLE_IMAGE_HEIGHT_RULE = ":where(article img){height:auto}"

    # Prepend {ARTICLE_IMAGE_HEIGHT_RULE} unless a style element already has it.
    #
    # @param doc [Nokogiri::XML::Document] parsed page
    # @return [void]
    def self.release_article_image_height(doc)
      return if article_image_height_rule?(doc)

      head = doc.at_css("head")
      return unless head

      style = doc.create_element("style")
      style.content = ARTICLE_IMAGE_HEIGHT_RULE
      head.prepend_child(style)
    end

    # @param doc [Nokogiri::XML::Document] parsed page
    # @return [Boolean] true when the height rule is already present
    def self.article_image_height_rule?(doc)
      needle = ARTICLE_IMAGE_HEIGHT_RULE.gsub(/\s+/, "")
      doc.css("style").any? do |node|
        node.content.gsub(/\s+/, "").include?(needle)
      end
    end
    private_class_method :release_article_image_height, :article_image_height_rule?

    # Check if a document outputs HTML (not CSS, JS, etc.)
    #
    # @param doc [Jekyll::Document, Jekyll::Page] the document to check
    # @return [Boolean] true if the document outputs HTML
    def self.html_document?(doc)
      ext = File.extname(doc.path || doc.url || "").downcase
      [".html", ".htm", ".md", ".markdown"].include?(ext)
    end
  end
end

# Register Jekyll hooks
Jekyll::Hooks.register :site, :post_read do |site|
  JekyllAutoThumbnails::Hooks.initialize_system(site)
end

Jekyll::Hooks.register :site, :post_render do |site|
  JekyllAutoThumbnails::Hooks.process_site(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  JekyllAutoThumbnails::Hooks.copy_thumbnails(site)
end
