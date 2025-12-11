# frozen_string_literal: true

require "jekyll"
require "nokogiri"

require_relative "jekyll-auto-thumbnails/version"
require_relative "jekyll-auto-thumbnails/configuration"
require_relative "jekyll-auto-thumbnails/url_resolver"
require_relative "jekyll-auto-thumbnails/digest_calculator"
require_relative "jekyll-auto-thumbnails/registry"
require_relative "jekyll-auto-thumbnails/generator"
require_relative "jekyll-auto-thumbnails/scanner"
require_relative "jekyll-auto-thumbnails/hooks"

module JekyllImgOptimizer
  # Main plugin module
end
