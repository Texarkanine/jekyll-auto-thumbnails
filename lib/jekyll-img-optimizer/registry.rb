# frozen_string_literal: true

module JekyllImgOptimizer
  # Image requirement registry
  #
  # Tracks images needing thumbnails and their required dimensions.
  # Handles duplicate registrations by keeping the largest dimensions.
  class Registry
    # Initialize empty registry
    def initialize
      @entries = {}
    end

    # Register an image with required dimensions
    #
    # @param url [String] image URL
    # @param width [Integer, nil] required width
    # @param height [Integer, nil] required height
    def register(url, width, height)
      existing = @entries[url]

      if existing
        # Update to max dimensions
        @entries[url] = {
          width: [existing[:width], width].compact.max,
          height: [existing[:height], height].compact.max
        }
      else
        @entries[url] = { width: width, height: height }
      end
    end

    # Check if image is registered
    #
    # @param url [String] image URL
    # @return [Boolean] true if registered
    def registered?(url)
      @entries.key?(url)
    end

    # Get requirements for image
    #
    # @param url [String] image URL
    # @return [Hash, nil] {width:, height:} or nil if not registered
    def requirements_for(url)
      @entries[url]&.dup
    end

    # Get all registered entries
    #
    # @return [Hash] url => {width:, height:}
    def entries
      @entries.dup
    end
  end
end


