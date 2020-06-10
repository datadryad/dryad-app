require 'http'

module Stash
  module Download
    # Dir.glob(File.expand_path('download/*.rb', __dir__)).sort.each(&method(:require))

    # this is pretty much the same as the built-in http.rb normalizer, but doesn't normalize the path because it was
    # changing the already-set encoding which was the one that worked
    #
    # set up your HTTP client like
    # http = HTTP.use(:normalize_uri => {:normalizer => Stash::Download::NORMALIZER})   -- rest of options after this
    # And now http.get will not mangle the URL into new characters.
    #
    # The change here from the default normalizer in http.rb is that this was the old value :path => uri.normalized_path
    NORMALIZER = lambda do |uri|
      uri = HTTP::URI.parse uri

      HTTP::URI.new(
          :scheme    => uri.normalized_scheme,
          :authority => uri.normalized_authority,
          :path      => uri.path,
          :query     => uri.query,
          :fragment  => uri.normalized_fragment
      )
    end
  end
end
