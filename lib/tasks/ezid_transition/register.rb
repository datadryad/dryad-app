require 'ezid/client'

module Tasks
  module EzidTransition
    module Register

      SAMPLE_DC4_XML = <<~XML.freeze
<?xml version="1.0" encoding="UTF-8"?>
<resource
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="http://datacite.org/schema/kernel-4" xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd">
    <identifier identifierType="DOI">10.7959/S85H-9D15</identifier>
    <creators>
        <creator>
            <creatorName nameType="Organizational">Dryad Digital Repository</creatorName>
            <affiliation affiliationIdentifier="https://ror.org/00x6h5n95" affiliationIdentifierScheme="ROR" schemeURI="https://ror.org">Dryad Digital Repository</affiliation>
        </creator>
    </creators>
    <titles>
        <title xml:lang="en">Dryad in-progress dataset</title>
    </titles>
    <publisher>Dryad</publisher>
    <publicationYear>2023</publicationYear>
    <resourceType resourceTypeGeneral="Dataset">Dataset</resourceType>
    <sizes/>
    <formats/>
    <version/>
    <descriptions>
        <description descriptionType="Abstract">A placeholder for an item to be published.</description>
    </descriptions>
</resource>
      XML

      def register_doi(doi:)
        params = { status: 'public', datacite: SAMPLE_DC4_XML.gsub('10.7959/S85H-9D15', doi) }
        # find correct tenant from DOI
        #
        owner = tenant.identifier_service.owner

      end

    end
  end
end
