# frozen_string_literal: true

require "nokogiri"
# Nokogiri::HTML5 ships with Nokogiri on CRuby but is not available on JRuby.
# Configuration rejects `parser: :html5` under JRuby, so this require only
# needs to succeed on CRuby. On JRuby, the HTML4 branch is the only path
# that ever runs.
require "nokogiri/html5" unless RUBY_ENGINE == "jruby"

module JekyllAutoThumbnails
  # Dispatch between Nokogiri's HTML5 and libxml2-based HTML4 parsers.
  #
  # HTML5 is the default throughout the gem; HTML4 is kept as an opt-in for
  # users who depended on libxml2's serialization quirks (notably the
  # injected `<meta http-equiv="Content-Type">`).
  module HtmlParser
    module_function

    # Parse an HTML string with the selected parser.
    #
    # @param html [String] HTML source
    # @param parser [Symbol] :html5 or :html4
    # @return [Nokogiri::HTML5::Document, Nokogiri::HTML4::Document]
    # @raise [ArgumentError] for an unknown parser symbol
    # @raise [NameError] if :html5 is requested under JRuby (should be
    #   prevented by Configuration validation; this is a belt-and-suspenders
    #   guard)
    def parse(html, parser)
      case parser
      when :html5
        Nokogiri::HTML5.parse(html)
      when :html4
        Nokogiri::HTML(html)
      else
        raise ArgumentError, "Unknown HTML parser: #{parser.inspect}"
      end
    end
  end
end
