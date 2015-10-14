require 'stash/wrapper'

module Stash
  module Harvester
    # Metadata support for {https://dash.cdlib.org/stash_wrapper/stash_wrapper.xsd the Stash XML Wrapper format}
    module Solr
      Dir.glob(File.expand_path('../wrapped_datacite/*.rb', __FILE__), &method(:require))
    end
  end
end
