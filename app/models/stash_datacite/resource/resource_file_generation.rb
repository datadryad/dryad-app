require 'zip'
require 'datacite/mapping'
require 'stash/wrapper'
require 'tempfile'
require 'stash_ezid/client'
require 'fileutils'

module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource, current_tenant)
        @resource = resource
        @current_tenant = current_tenant
        @version = @resource.next_version
        ResourceFileGeneration.set_pub_year(@resource)
        @client = StashEzid::Client.new(@current_tenant.identifier_service.to_h)
      end

      def generate_identifier
        if @resource.identifier
          "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}"
        else
          @client.mint_id
        end
      end

      def generate_xml(target_url, identifier)
        simple_id = identifier.split(':', 2)[1]

        dm = Datacite::Mapping
        st = Stash::Wrapper

        case @resource.resource_type.resource_type
          when "Spreadsheet"
            @type = dm::ResourceTypeGeneral::DATASET
          when "MultipleTypes"
            @type = dm::ResourceTypeGeneral::COLLECTION
          when "Image"
            @type = dm::ResourceTypeGeneral::IMAGE
          when "Sound"
            @type = dm::ResourceTypeGeneral::SOUND
          when "Video"
            @type = dm::ResourceTypeGeneral::AUDIOVISUAL
          when "Text"
            @type = dm::ResourceTypeGeneral::TEXT
          when "Software"
            @type = dm::ResourceTypeGeneral::SOFTWARE
          else
            @type = dm::ResourceTypeGeneral::OTHER
        end
        # # Based on "Example for a simple dataset"
        # # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml

        resource = dm::Resource.new(
          identifier: dm::Identifier.new(value: simple_id),

          creators: @resource.creators.map do |creator|
            dm::Creator.new(name: "#{creator.creator_full_name}")
          end,

          contributors: @resource.contributors.map do |contributor|
            dm::Contributor.new(name: "#{contributor.contributor_name}", type: dm::ContributorType::FUNDER)
          end,

          titles: [
              dm::Title.new(value: "#{@resource.titles.where(title_type: :main).first.title}")
          ],

          publisher: "#{@current_tenant.long_name || 'unknown'}",

          publication_year: Time.now.year,

          subjects: @resource.subjects.map do |subject|
            dm::Subject.new(value: "#{subject.subject}")
          end,

          language: 'en',

          resource_type: dm::ResourceType.new(resource_type_general: @type, value: "#{@resource.resource_type.resource_type}" ),

          version: @version,

          descriptions: [
            dm::Description.new(
                type: dm::DescriptionType::ABSTRACT,
                value: "#{@resource.descriptions.where(description_type: :abstract).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::METHODS,
                value: "#{@resource.descriptions.where(description_type: :methods).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::OTHER,
                value: "#{@resource.descriptions.where(description_type: :usage_notes).first.description}"
            )
          ]
        )

        datacite_to_wrapper = resource.save_to_xml
        datacite_root = resource.write_xml
        @client.update_metadata(identifier, datacite_root, target_url) # add target as 3rd parameter

        # datacite_target = "#{@resource.id}_datacite.xml"
        # datacite_directory = "#{Rails.root}/uploads"
        # puts Dir.pwd
        #f = File.open("#{datacite_directory}/#{datacite_target}", 'w') { |f| f.write(datacite_root) }

        identifier = st::Identifier.new(
          type: st::IdentifierType::DOI,
          value: '10.14749/1407399498'
        )

        version = st::Version.new(
          number: @version,
          date:  Date.tomorrow,
          note: 'Sample wrapped Datacite document'
        )

        r = @resource.rights.try(:first)
        license = st::License.new(name: r.rights , uri: r.rights_uri) if r

        embargo = st::Embargo.new(
          type: st::EmbargoType::NONE,
          period: 'none',
          start_date: Date.tomorrow,
          end_date: Date.tomorrow,
        )

        uploads = uploads_list(@resource)
        files = uploads.map do |d|
          st::StashFile.new(
            pathname: "#{d[:name]}", size_bytes: d[:size], mime_type: "#{d[:type]}"
          )
        end
        inventory = st::Inventory.new(files: files)

        wrapper = st::StashWrapper.new(
          identifier: identifier,
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory,
          descriptive_elements: [datacite_to_wrapper]
        )

        stash_wrapper = wrapper.write_xml
        # stash_wrapper_target = "#{@resource.id}_stash_wrapper.xml"
        # stash_wrapper_directory = "#{Rails.root}/uploads"
        # puts Dir.pwd
        # f = File.open("#{stash_wrapper_directory}/#{stash_wrapper_target}", 'w') { |f| f.write(stash_wrapper) }
        return [datacite_root, stash_wrapper]
      end

      def generate_dublincore
        dc_builder = Nokogiri::XML::Builder.new do |xml|
          xml.qualifieddc('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                          'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd',
                          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                          'xmlns:dcterms' => 'http://purl.org/dc/terms/') {

            @resource.creators.each do |c|
              xml.send(:'dc:creator', "#{c.creator_full_name.gsub(/\r/,"")}")
            end

            @resource.contributors.each do |c|
              xml.send(:'dc:contributor', "#{c.contributor_name.gsub(/\r/,"")}")
              xml.send(:'dc:description', "#{c.award_number.gsub(/\r/,"")}")
            end

            xml.send(:'dc:title', "#{@resource.titles.where(title_type: :main).first.title}")
            xml.send(:'dc:publisher', "#{@current_tenant.long_name || 'unknown'}")
            xml.send(:'dc:date', Time.now.year)

            @resource.subjects.each do |s|
              xml.send(:'dc:subject', "#{s.subject.gsub(/\r/,"")}")
            end

            xml.send(:'dc:type', "#{@resource.resource_type.resource_type}")
            #xml.send(:'dcterms:extent', @total_size)

            @resource.rights.each do |r|
              xml.send(:'dc:rights', "#{r.rights}")
              xml.send(:'dcterms:license', "#{r.rights_uri}", "xsi:type" => "dcterms:URI")
            end

            unless @resource.descriptions.blank?
              @resource.descriptions.each do |d|
                xml.send(:'dc:description', "#{d.description.to_s.gsub(/\r/,"")}")
              end
            end

            @relation_types = StashDatacite::RelationType.all
            @resource.related_identifiers.each do |r|

              case r.relation_type
                when "IsPartOf"
                  xml.send(:'dcterms:isPartOf', "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "HasPart"
                  xml.send(:'dcterms:hasPart',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsCitedBy"
                  xml.send(:'dcterms:isReferencedBy',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "Cites"
                  xml.send(:'dcterms:references',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsReferencedBy"
                  xml.send(:'dcterms:isReferencedBy',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "References"
                  xml.send(:'dcterms:references',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsNewVersionOf"
                  xml.send(:'dcterms:isVersionOf',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsPreviousVersionOf"
                  xml.send(:'dcterms:hasVersion',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsVariantFormOf"
                  xml.send(:'dcterms:isVersionOf',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsOriginalFormOf"
                  xml.send(:'dcterms:hasVersion',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
                else
                  xml.send(:'dcterms:relation',  "#{r.related_identifier_type}" + ": " + "#{r.related_identifier}")
              end
            end

          }
        end
        dc_builder.to_xml.to_s
      end

      def generate_dataone
        files = uploads_list(@resource)
        content =   "#%dataonem_0.1 " + "\n" +
            "#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-dataone-manifest " + "\n" +
            "#%prefix | dom: | http://uc3.cdlib.org/ontology/dataonem " + "\n" +
            "#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom " + "\n" +
            "#%fields | dom:scienceMetadataFile | dom:scienceMetadataFormat | " +
            "dom:scienceDataFile | mrt:mimeType " + "\n"

        files.each do |file|
          if file
            content <<  "mrt-datacite.xml |  http://datacite.org/schema/kernel-3.1 | " +
                "#{file[:name]}" + " | #{file[:type]} " + "\n" + "mrt-oaidc.xml | " +
                "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd | " +
                "#{file[:name]}" + " | #{file[:type]} " + "\n"
          end
        end
        content << "#%eof "
        content.to_s
      end

      def generate_merritt_zip(target_url, identifier)
        target_url = target_url
        folder = "#{Rails.root}/uploads"
        FileUtils::mkdir_p(folder)

        uploads = uploads_list(@resource)
        purge_existing_files

        zipfile_name = "#{folder}/#{@resource.id}_archive.zip"
        datacite_xml, stashwrapper_xml = generate_xml(target_url, identifier)

        File.open("#{folder}/#{@resource.id}_mrt-datacite.xml", "w") do |f|
          f.write datacite_xml
        end
        File.open("#{folder}/#{@resource.id}_stash-wrapper.xml", "w") do |f|
          f.write stashwrapper_xml
        end
        File.open("#{folder}/#{@resource.id}_mrt-oaidc.xml", "w") do |f|
          f.write(generate_dublincore)
        end
        File.open("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt", 'w') do |f|
          f.write(generate_dataone)
        end

        Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
          zipfile.add("mrt-datacite.xml", "#{folder}/#{@resource.id}_mrt-datacite.xml")
          zipfile.add("stash-wrapper.xml", "#{folder}/#{@resource.id}_stash-wrapper.xml")
          zipfile.add("mrt-oaidc.xml", "#{folder}/#{@resource.id}_mrt-oaidc.xml")
          zipfile.add("mrt-dataone-manifest.txt", "#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
          uploads.each do |d|
            zipfile.add("#{d[:name]}", "#{folder}/#{@resource.id}/#{d[:name]}")
          end
        end
      end

      def purge_existing_files
        folder = "#{Rails.root}/uploads/"
        if File.exist?("#{folder}/#{@resource.id}_archive.zip")
          File.delete("#{folder}/#{@resource.id}_archive.zip")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-datacite.xml")
          File.delete("#{folder}/#{@resource.id}_mrt-datacite.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_stash-wrapper.xml")
          File.delete("#{folder}/#{@resource.id}_stash-wrapper.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-oaidc.xml")
          File.delete("#{folder}/#{@resource.id}_mrt-oaidc.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
          File.delete("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
        end
      end

      def uploads_list(resource)
        files = []
        current_uploads = resource.file_uploads
        current_uploads.each do |u|
          hash = { name: u.upload_file_name, type: u.upload_content_type, size: u.upload_file_size }
          files.push(hash)
        end
        files
      end

      # set the publication year to the current one if it has not been set yet
      def self.set_pub_year(resource)
        return if resource.publication_years.count > 0
        PublicationYear.create({publication_year: Time.now.year, resource_id: resource.id})
      end

    end
  end
end
