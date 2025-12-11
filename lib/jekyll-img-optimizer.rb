# frozen_string_literal: true

require "jekyll"
require "nokogiri"

require_relative "jekyll-img-optimizer/version"
require_relative "jekyll-img-optimizer/configuration"
require_relative "jekyll-img-optimizer/url_resolver"
require_relative "jekyll-img-optimizer/digest_calculator"
require_relative "jekyll-img-optimizer/registry"
require_relative "jekyll-img-optimizer/generator"
require_relative "jekyll-img-optimizer/scanner"
require_relative "jekyll-img-optimizer/hooks"

module JekyllImgOptimizer
  # Main plugin module
end
