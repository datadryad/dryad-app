# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'
require 'http'
require 'fileutils'
require 'cgi'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe MetadataGenerator do

      before(:each) do
        @resource = create(:resource)
        4.times do
          place = create(:geolocation_place)
          point = create(:geolocation_point)
          box = create(:geolocation_box)
          create(:geolocation, place_id: place.id, point_id: point.id, box_id: box.id, resource_id: @resource.id)
        end
        @g = @resource.geolocations
        @g[0].update(point_id: nil, box_id: nil) # remove point and box
        @g[1].update(place_id: nil, box_id: nil) # remove place and box
        @g[2].update(place_id: nil, point_id: nil) # remove place and point
        # g[3] has all 3

        create(:description, description_type: 'other', resource_id: @resource.id)
        create(:description, description_type: 'methods', resource_id: @resource.id)

        @resource.update(contributors: []) # erase the default funder
        @funder1 = create(:contributor, resource_id: @resource.id)
        @funder2 = create(:contributor, resource_id: @resource.id, award_number: nil)

        @resource.reload

        @mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource)
      end

      it 'has doi output' do
        expect(@mg.doi).to eq("https://doi.org/#{@resource.identifier.identifier}")
      end

      it 'has upload_type output' do
        create(:resource_type, resource_id: @resource.id)
        expect(@mg.upload_type).to eq(@resource.resource_type.resource_type_general)
      end

      it 'has publication_date output' do
        expect(@mg.publication_date).to eq(@resource&.publication_date&.strftime('%Y-%m-%d'))
      end

      it 'has title output' do
        expect(@mg.title).to eq(@resource.title)
      end

      it 'has creators output' do
        cr = @mg.creators.first
        au = @resource.authors.first
        expect(cr[:orcid]).to eq(au.author_orcid)
        expect(cr[:name]).to eq("#{au.author_last_name}, #{au.author_first_name}")
        expect(cr[:affiliation]).to eq(au.affiliation.long_name)
      end

      it 'has description output' do
        expect(@mg.description).to eq(@resource.descriptions.where(description_type: 'abstract').first.description)
      end

      it 'has access_right output' do
        expect(@mg.access_right).to eq('open')
      end

      it 'has license output' do
        create(:right, resource_id: @resource.id)
        expect(@mg.license).to eq('cc-zero')
      end

      it 'sets license to cc-zero for supplemental information' do
        @mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource, dataset_type: :supp)
        expect(@mg.license).to eq('CC-BY-4.0')
      end

      it 'has keywords output' do
        s = create(:subject)
        @resource.subjects << s
        expect(@mg.keywords.first).to eq(@resource.subjects.non_fos.first.subject)
      end

      it 'has notes output' do
        expect(@mg.notes).to include(@resource.descriptions.where(description_type: 'other').first.description)
      end

      it 'puts funder information into notes' do
        expect(@mg.notes).to include(CGI.escapeHTML("Funding provided by: #{@funder1.contributor_name}"))
        expect(@mg.notes).to include(CGI.escapeHTML("Crossref Funder Registry ID: #{@funder1.name_identifier_id}"))
        expect(@mg.notes).to include(CGI.escapeHTML("Award Number: #{@funder1.award_number}"))
        expect(@mg.notes).to include(CGI.escapeHTML("Funding provided by: #{@funder2.contributor_name}"))
        expect(@mg.notes).to include(CGI.escapeHTML("Crossref Funder Registry ID: #{@funder2.name_identifier_id}"))
        expect(@mg.notes.scan('Award Number').count).to eq(1)
      end

      it 'sets an item to the community' do
        expect(@mg.communities).to eq([{ identifier: APP_CONFIG.zenodo.community_id }])
      end

      it 'has method output' do
        expect(@mg.method).to eq(@resource.descriptions.where(description_type: 'methods').first.description)
      end

      it 'has geolocation point output' do
        expect(@mg.locations[1]).to eq('lat' => @g[1].geolocation_point.latitude, 'lon' => @g[1].geolocation_point.longitude)
      end

      it 'has geolocation place' do
        expect(@mg.locations[0]).to eq('place' => @g[0].geolocation_place.geo_location_place)
      end

      it 'has both point and place' do
        expect(@mg.locations[2]).to eq('lat' => @g[3].geolocation_point.latitude, 'lon' => @g[3].geolocation_point.longitude,
                                       'place' => @g[3].geolocation_place.geo_location_place)
      end

      describe :software_generation do
        before(:each) do
          # takes what is done for the general replication case and adds stuff for software
          @sl = StashEngine::SoftwareLicense.create(name: 'MIT License', identifier: 'MIT', details_url: 'http://spdx.org/licenses/MIT.json')
          @resource.identifier.update(software_license_id: @sl.id)

          test_doi = "https://doi.org/#{rand.to_s[2..3]}.#{rand.to_s[2..5]}/zenodo.#{rand.to_s[2..11]}"
          @related_id = create(:related_identifier, related_identifier: test_doi, related_identifier_type: 'doi',
                                                    relation_type: 'ispartof', resource_id: @resource.id,
                                                    verified: true, hidden: false, added_by: 'zenodo')

          @related_id2 = create(:related_identifier, resource_id: @resource.id, verified: true, hidden: false)

          @mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource, dataset_type: :software)
        end

        it 'changes upload_type to :software' do
          expect(@mg.upload_type).to eq('software')
        end

        it 'sets the software license instead of the dataset license' do
          expect(@mg.license).to eq(@sl.identifier)
        end

        it "removes our dryad citation link for zenodo because this is that citation object's metadata" do
          ids = @mg.related_identifiers.map { |i| i[:identifier] }
          expect(ids).to include(@related_id2.related_identifier) # other relation should still exist
          expect(ids).not_to include(@related_id.related_identifier) # zenodo id for this shouldn't exist
        end

        it 'adds isSourceOf to the Zenodo software to reference the Dryad dataset' do
          ids = @mg.related_identifiers.map { |i| i[:identifier] }
          expect(ids).to include(StashDatacite::RelatedIdentifier.standardize_doi(@resource.identifier.identifier))
        end
      end

      describe :supp_generation do
        before(:each) do
          # takes what is done for the general replication case and adds stuff for supplemental

          test_doi = "https://doi.org/#{rand.to_s[2..3]}.#{rand.to_s[2..5]}/zenodo.#{rand.to_s[2..11]}"
          @related_id = create(:related_identifier, related_identifier: test_doi, related_identifier_type: 'doi',
                                                    relation_type: 'issourceof', resource_id: @resource.id,
                                                    verified: true, hidden: false, added_by: 'zenodo')

          @related_id2 = create(:related_identifier, resource_id: @resource.id, verified: true, hidden: false)

          @mg = Stash::ZenodoReplicate::MetadataGenerator.new(resource: @resource, dataset_type: :supp)
        end

        it 'changes resource type to other for :supp' do
          expect(@mg.upload_type).to eq('other')
        end

        it "removes our dryad citation link for zenodo because this is that citation object's metadata" do
          ids = @mg.related_identifiers.map { |i| i[:identifier] }
          expect(ids).to include(@related_id2.related_identifier) # other relation should still exist
          expect(ids).not_to include(@related_id.related_identifier) # zenodo id for this shouldn't exist
        end

        # the software is the source of the data
        it 'adds isSourceOf to the Zenodo software to reference the Dryad dataset' do
          ids = @mg.related_identifiers.map { |i| i[:identifier] }
          expect(ids).to include(StashDatacite::RelatedIdentifier.standardize_doi(@resource.identifier.identifier))
        end
      end
    end
  end
end
