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
      def self.ensure_camel_case(str)
        str.split('_').collect { |s| s.sub(/./, &:upcase) }.join if str
      end

      # Ensures that the specified argument is either a ++Date++, a UTC ++Time++, or nil
      # @param time [Time, Date, nil] the time
      # @return the argument
      # @raise ArgumentError if +time+ is not a ++Date++ or ++Time++-like object, or
      #   if it is a ++Time++ not in UTC
      def self.utc_or_nil(time)
        if time
          if time.respond_to?(:utc?)
            fail ArgumentError, "time #{time} must be in UTC" unless time.utc?
          else
            fail ArgumentError, "time #{time} does not appear to be a time or date" unless time.respond_to?(:strftime)
          end
        end
        time
      end

      def self.keys_to_syms(v)
        return v unless v.respond_to?(:to_h)
        v.to_h.map { |k2, v2| [k2.to_sym, keys_to_syms(v2)] }.to_h
      end

    end
  end
end
