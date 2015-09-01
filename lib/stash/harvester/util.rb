module Stash
  module Harvester
    # Misc utility methods
    module Util
      # Ensures that the specified argument is a URI.
      # @param url [String, URI] The argument. If the argument is already
      #   a URI, it is returned unchanged; otherwise, the argument's string
      #   form (as returned by ++to_s++) is parsed as a URI.
      # @return [nil, URI] ++nil++ if ++url++ is nil, otherwise the URI.
      # @raise [URI::InvalidURIError] if +url+ is a string that is not a valid URI
      def self.to_uri(url)
        return nil unless url
        return url if url.is_a? URI
        stripped = url.respond_to?(:strip) ? url.strip : url.to_s.strip
        URI.parse(stripped)
      end

      # Ensures that the first character of the specified string
      # (if any) is capitalized. If the first character is not an
      # ASCII letter, or the string is empty, the returned string
      # is unchanged.
      #
      # @param str [String] the string
      # @return [String] a copy of the string with the first character
      #   capitalized (if applicable)
      def self.ensure_leading_cap(str)
        str.sub(/./, &:upcase) if str
      end
    end
  end
end
