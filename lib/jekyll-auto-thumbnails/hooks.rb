# frozen_string_literal: true

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

        doc.output = replace_urls(doc.output, url_map)
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

    # Replace image URLs in HTML
    #
    # @param html [String] HTML content
    # @param url_map [Hash] original URL => thumbnail URL
    # @return [String] modified HTML
    def self.replace_urls(html, url_map)
      # Return early if no replacements needed
      return html if url_map.empty?

      doc = Nokogiri::HTML(html)

      doc.css("article img").each do |img|
        src = img["src"]
        next unless src

        # Find thumbnail URL for this image
        thumb_url = url_map[src]
        img["src"] = thumb_url if thumb_url
      end

      # Serialize with encoding declaration to match Jekyll output
      doc.to_html
    end

    # Check if a document is HTML (not CSS, JS, etc.)
    #
    # @param doc [Jekyll::Document, Jekyll::Page] the document to check
    # @return [Boolean] true if the document appears to be HTML
    def self.html_document?(doc)
      # Check file extension from path or URL - only process .html/.htm files
      path = doc.path || doc.url || ""
      ext = File.extname(path).downcase
      return true if [".html", ".htm"].include?(ext)

      # Check output content - must clearly look like HTML
      output = doc.output.to_s.strip
      return false if output.empty?
      
      # If output starts with HTML indicators, it's HTML
      return true if output.start_with?("<!DOCTYPE", "<html", "<!doctype", "<HTML")

      # Check content type if available
      if doc.respond_to?(:data) && doc.data["content_type"]
        return doc.data["content_type"].include?("text/html")
      end

      # Default: skip if we can't confidently identify as HTML
      # This is safer than assuming HTML, as non-HTML files (like CSS) can be processed as pages
      false
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
