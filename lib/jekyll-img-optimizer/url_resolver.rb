# frozen_string_literal: true

module JekyllImgOptimizer
  # URL resolution and path handling
  #
  # Handles conversion between URLs (as seen in HTML) and filesystem paths,
  # distinguishes between external URLs and local paths, and resolves relative paths.
  module UrlResolver
    # Check if URL is external (http/https/protocol-relative)
    #
    # @param url [String] URL to check
    # @return [Boolean] true if external URL
    def self.external?(url)
      url.start_with?("http://", "https://", "//")
    end

    # Resolve relative path to absolute site-relative path
    #
    # @param url [String] URL or path
    # @param base_dir [String] Base directory for relative resolution
    # @return [String, nil] resolved path or nil if external
    def self.resolve_path(url, base_dir)
      return nil if external?(url)
      return url if url.start_with?("/")

      # Relative path - resolve against base_dir
      # Remove ./ prefix if present
      cleaned_url = url.sub(%r{^\./}, "")
      
      # Join with base_dir and normalize
      require "pathname"
      Pathname.new(File.join(base_dir, cleaned_url)).cleanpath.to_s
    end

    # Convert site-relative URL to filesystem path
    #
    # @param url [String] Site-relative URL (e.g., /assets/image.jpg)
    # @param site_source [String] Jekyll site source directory
    # @return [String, nil] filesystem path or nil if external
    def self.to_filesystem_path(url, site_source)
      return nil if external?(url)

      # Strip leading slash and join with site source
      cleaned_url = url.sub(%r{^/}, "")
      File.join(site_source, cleaned_url)
    end
  end
end

