# frozen_string_literal: true

require_relative "html_parser"

module JekyllAutoThumbnails
  # Jekyll hook integration
  module Hooks
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

      # Scan all documents and pages
      (site.documents + site.pages).each do |doc|
        next unless doc.output
        next unless html_document?(doc)

        Scanner.scan_html(doc.output, registry, config, site.source)
      end

      Jekyll.logger.info "AutoThumbnails:", "Found #{registry.entries.size} images to optimize"

      # Generate thumbnails
      url_map = {}
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
        else
          Jekyll.logger.warn "AutoThumbnails:", "Failed to generate thumbnail for #{url}"
        end
      end

      # Store url_map for post_write hook
      site.data["auto_thumbnails_url_map"] = url_map

      # Replace URLs in HTML
      (site.documents + site.pages).each do |doc|
        next unless doc.output
        next unless html_document?(doc)

        doc.output = replace_urls(doc.output, url_map, parser: config.parser)
      end

      Jekyll.logger.info "AutoThumbnails:", "Generated #{url_map.size} thumbnails"
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

      url_map.each_value do |thumb_url|
        thumb_filename = File.basename(thumb_url)
        cached_path = File.join(config.cache_dir, thumb_filename)

        # Build destination path in _site preserving directory structure
        dest_path = File.join(site.dest, thumb_url.sub(%r{^/}, ""))
        dest_dir = File.dirname(dest_path)

        FileUtils.mkdir_p(dest_dir)
        FileUtils.cp(cached_path, dest_path)
      end

      Jekyll.logger.info "AutoThumbnails:", "All thumbnails copied"
    end

    # Replace image URLs in HTML.
    #
    # Returns the input string unchanged (object identity) when no replacement
    # was actually made. This is both a perf win for pages with no matching
    # images and a correctness win: the HTML4 path otherwise round-trips every
    # page through libxml2's serializer, which injects a spurious
    # `<meta http-equiv="Content-Type">` on HTML5 sites.
    #
    # @param html [String] HTML content
    # @param url_map [Hash] original URL => thumbnail URL
    # @param parser [Symbol] :html5 (default) or :html4
    # @return [String] modified HTML (or the input itself, unchanged)
    def self.replace_urls(html, url_map, parser: :html5)
      return html if url_map.empty?
      return html unless html.match?(/<img/i)

      doc = HtmlParser.parse(html, parser)

      modified = false
      doc.css("article img").each do |img|
        src = img["src"]
        next unless src

        thumb_url = url_map[src]
        next unless thumb_url

        img["src"] = thumb_url
        modified = true
      end

      modified ? doc.to_html : html
    end

    # Check if a document outputs HTML (not CSS, JS, etc.)
    #
    # @param doc [Jekyll::Document, Jekyll::Page] the document to check
    # @return [Boolean] true if the document outputs HTML
    def self.html_document?(doc)
      ext = File.extname(doc.path || doc.url || "").downcase
      [".html", ".htm", ".md", ".markdown"].include?(ext)
    end

    private_class_method :replace_urls, :html_document?
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
