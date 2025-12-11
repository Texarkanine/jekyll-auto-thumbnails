# frozen_string_literal: true

require "digest/md5"

module JekyllImgOptimizer
  # MD5 digest calculation for cache keys
  #
  # Computes short MD5 digests of image files for use in thumbnail filenames.
  module DigestCalculator
    # Compute short (6-char) MD5 digest of file
    #
    # @param file_path [String] path to file
    # @return [String] first 6 characters of MD5 hex digest
    # @raise [Errno::ENOENT] if file doesn't exist
    def self.short_digest(file_path)
      Digest::MD5.file(file_path).hexdigest[0...6]
    end
  end
end
