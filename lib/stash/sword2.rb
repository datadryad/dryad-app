require 'uri'

module Stash
  module Sword2
    Dir.glob(File.expand_path('../sword2/*.rb', __FILE__)).sort.each(&method(:require))

    # Ensures that the specified argument is a URI.
    # @param url [String, URI] The argument. If the argument is already
    #   a URI, it is returned unchanged; otherwise, the argument's string
    #   form (as returned by `to_s`) is parsed as a URI.
    # @return [URI, nil] The URI, or `nil` if `url` is nil.
    # @raise [URI::InvalidURIError] if `url` is a string that is not a valid URI
    def self.to_uri(url)
      return nil unless url
      return url if url.is_a? URI
      stripped = url.to_s.strip
      URI.parse(stripped)
    end
  end
end
