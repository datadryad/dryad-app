require 'ezid-client'
module StashEngine
  class Ezid

    def self.mint_test
      ::Ezid::Client.configure do |config|
        config.default_shoulder = "ark:/99999/fk4"
        config.user = "apitest"
        config.password = "apitest"
      end

      # mint reserved identifier
      # , '_target' => "http://example.com/path%20with%20spaces", "dc.creator" => "Me"
      ezid = ::Ezid::Identifier.mint("doi:10.5072/FK2", {:status => "reserved"})
      puts ezid.id

      # update xml with identifier
      xml_path = File.join(StashEngine::Engine.root, 'test', 'fixtures', 'stash_engine', 'datacite-sample.xml')
      xml_str = File.read(xml_path)
      xml_str.gsub!('<identifier identifierType="DOI">10.1594/WDCC/CCSRNIES_SRES_B2</identifier>',
          '<identifier identifierType="DOI">' + ezid.id[4..-1] + '</identifier>')

      # update reserved EZID item with full metadata
      ::Ezid::Identifier.modify(ezid.id, {:status => "public", :datacite => xml_str })
      puts "updated #{ezid.id} if no errors"
    end
  end
end