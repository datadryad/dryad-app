require 'spec_helper'
require 'ostruct'
require 'datacite/mapping'
require 'byebug'
require_relative '../../../../../spec_helpers/factory_helper'

module Datacite
  module Mapping

    describe GeoLocationBox do
      describe '#to_envelope' do
        it 'should convert a box to an ENVELOPE() with coordinates in correct order' do
          box = GeoLocationBox.new(16.31591, 73.480431, 22.672657, 83.068985)
          expect(box.to_envelope).to eq('ENVELOPE(73.480431, 83.068985, 22.672657, 16.31591)')
        end
      end
    end

    describe 'Description' do
      desc_value = 'Data were created with funding from the Ministry of Magic under grant 319995.'

      describe '#funding?' do
        it 'returns true for funding and false for other descriptions' do
          funding_desc = Description.new(type: DescriptionType::OTHER, value: desc_value)
          expect(funding_desc.funding?).to eq(true)
          usage_desc = Description.new(type: DescriptionType::OTHER, value: 'Some other value')
          expect(usage_desc.funding?).to eq(false)
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          expect(other_desc.funding?).to eq(false)
        end
      end

      describe '#usage?' do
        it 'returns true for usage and false otherwise' do
          funding_desc = Description.new(type: DescriptionType::OTHER, value: desc_value)
          expect(funding_desc.usage?).to eq(false)
          usage_desc = Description.new(type: DescriptionType::OTHER, value: 'Some other value')
          expect(usage_desc.usage?).to eq(true)
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          expect(other_desc.usage?).to eq(false)
        end
      end
    end
  end
end

module Stash
  module Indexer
    describe IndexingResource do
      # tried before :all and it randomly made certain tests fail and reloading returned nils, maybe something resetting it
      before :each do
        @user = create(:user)
        @identifier = create(:identifier)
        @internal_data = create(:internal_data, identifier_id: @identifier.id)
        @resource = create(:resource, identifier_id: @identifier.id, user_id: @user.id)
        @resource_state = create(:resource_state, resource_id: @resource.id)
        @resource.update(current_resource_state_id: @resource_state.id)
        @version = create(:version, resource_id: @resource.id)
        @affil1 = create(:affiliation)
        @affil2 = create(:affiliation, long_name: 'Orinda Tech')
        @author1 = create(:author, affiliations: [@affil1], resource_id: @resource.id)
        @author2 = create(:author, author_first_name: 'Horace', author_last_name: 'Liu', author_email: 'holyu@example.org',
                                   author_orcid: nil, affiliations: [@affil2], resource_id: @resource.id)
        @contributor = create(:contributor, resource_id: @resource.id)
        @datacite_date = create(:datacite_date, resource_id: @resource.id)
        @description1 = create(:description, resource_id: @resource.id)
        @description2 = create(:description, description: '<p>My methods were meticulous</p>', description_type: 'methods', resource_id: @resource.id)
        @description3 = create(:description, description:
            'Please <i>use</i> this data with care', description_type: 'other', resource_id: @resource.id)
        @geo_box1 = create(:geolocation_box)
        @geo_box2 = create(:geolocation_box, sw_latitude: 37, ne_latitude: 38, sw_longitude: -117, ne_longitude: -116)
        @geo_place1 = create(:geolocation_place)
        @geo_place2 = create(:geolocation_place, geo_location_place: 'Timbuktu')
        @geo_place3 = create(:geolocation_place, geo_location_place: 'Greenland')
        @geo_point1 = create(:geolocation_point)
        @geo_point2 = create(:geolocation_point, latitude: 41.23, longitude: -122.31)
        @geolocation1 = create(:geolocation, place_id: @geo_place1.id, point_id: @geo_point1.id, box_id: @geo_box1.id, resource_id: @resource.id)
        @geolocation2 = create(:geolocation, place_id: @geo_place2.id, box_id: @geo_box2.id, resource_id: @resource.id)
        @geolocation3 = create(:geolocation, place_id: @geo_place3.id, resource_id: @resource.id)
        @geolocation4 = create(:geolocation, box_id: @geo_box2.id, resource_id: @resource.id)
        @geolocation5 = create(:geolocation, point_id: @geo_point2.id, resource_id: @resource.id)
        @publication_year = create(:publication_year, resource_id: @resource.id)
        @publisher = create(:publisher, resource_id: @resource.id)
        @related_identifier = create(:related_identifier)
        @resource_type = create(:resource_type, resource_id: @resource.id)
        @right = create(:right, resource_id: @resource.id)
        @subject1 = create(:subject, resources: [@resource])
        @subject2 = create(:subject, subject: 'parsimonious', resources: [@resource])
        @resource.reload
        @ir = IndexingResource.new(resource: @resource)
      end

      describe '#default_title' do
        it 'returns the title' do
          expect(@ir.default_title).to eql(@resource.title)
        end
      end

      describe '#doi' do
        it 'returns the doi' do
          expect(@ir.doi).to eql(@identifier.to_s)
        end
      end

      describe '#type' do
        it 'returns the correct resource type' do
          expect(@ir.type).to eql(@resource.resource_type.resource_type.capitalize)
        end
      end

      describe '#general_type' do
        it 'returns the correct value' do
          expect(@ir.general_type.to_s.end_with?('Dataset')).to be_truthy
        end
      end

      describe '#creator_names' do
        it 'returns correct names' do
          expect(@ir.creator_names).to eql(['McVie, Gargcelia', 'Liu, Horace'])
        end
      end

      describe '#subjects' do
        it 'should match subjects' do
          expect(@ir.subjects).to eql(['freshwater cats', 'parsimonious'])
        end
      end

      describe '#publication_year' do
        it 'returns correct publication year' do
          expect(@ir.publication_year).to eql(2018)
        end
      end

      describe '#issued_date' do
        it 'returns a correct issued date' do
          expect(@ir.issued_date).to eql('2008-09-15T15:53:00Z')
        end
      end

      describe '#license_name' do
        it 'returns the correct license name' do
          expect(@ir.license_name).to eql(@right.rights)
        end
      end

      describe '#publisher' do
        it 'returns publisher name' do
          expect(@ir.publisher).to eql(@publisher.publisher)
        end
      end

      describe '#grant_number' do
        it 'returns the grant number' do
          expect(@ir.grant_number).to eql(@contributor.award_number)
        end
      end

      describe '#usage_notes' do
        it 'returns usage notes, free of html' do
          expect(@ir.usage_notes).to eql('Please use this data with care')
        end
      end

      describe '#descriptive_text_for' do
        it 'returns the methods, free of html' do
          expect(@ir.description_text_for(Datacite::Mapping::DescriptionType::METHODS)).to eql('My methods were meticulous')
        end

        it 'returns the abstract, free of html' do
          expect(@ir.description_text_for(Datacite::Mapping::DescriptionType::ABSTRACT)).to eql('Cat belowsquared')
        end
      end

      describe '#geo_location_places' do
        it 'returns a list of all place names' do
          expect(@ir.geo_location_places).to eql(%w[Oakland Timbuktu Greenland])
        end
      end

      describe '#geo_location_boxes' do
        it 'gives the right number of geolocation boxes' do
          expect(@ir.geo_location_boxes.count).to eql(3)
        end

        it 'gives the right class of geolocation boxes' do
          expect(@ir.geo_location_boxes.first.class).to eql(Datacite::Mapping::GeoLocationBox)
        end

        it 'should give the right value for a box' do
          ir_box = @ir.geo_location_boxes.second
          box = Datacite::Mapping::GeoLocationBox.new(37.0, -117.0, 38.0, -116.0)
          expect(ir_box).to eq(box)
        end

        # we can check actual values in the main output of the solr conversion much easier because it becomes a simple type
        # so deferring it to that method to check
      end

      describe '#geo_location_points' do
        it 'gives the right number of points' do
          expect(@ir.geo_location_points.count).to eql(2)
        end

        it 'gives the correct class of points' do
          expect(@ir.geo_location_points.first.class).to eql(Datacite::Mapping::GeoLocationPoint)
        end

        it 'gives correct values for a point' do
          ir_point = @ir.geo_location_points.second
          point = Datacite::Mapping::GeoLocationPoint.new(41.23, -122.31)
          expect(ir_point).to eq(point)
        end
      end

      describe '#datacite?' do
        it 'is true because we only use datacite right now' do
          expect(@ir.class.datacite?).to be_truthy
        end
      end

      describe '#calc_bounding_box' do
        it 'calculates a bounding box with a Datacite::Mapping object' do
          expect(@ir.calc_bounding_box.class).to eql(Datacite::Mapping::GeoLocationBox)
        end

        it 'should calculate the bounding box of a box as itself' do
          @resource.geolocations.each_with_index { |obj, index| obj.destroy if index != 0 } # delete all but first item
          @resource.geolocations.first.geolocation_point.destroy # destroy the point coordinates for this
          @resource.reload

          temp_ir = IndexingResource.new(resource: @resource)

          box = Datacite::Mapping::GeoLocationBox.new(34.270836, -128.671875, 43.612217, -95.888672)
          expect(temp_ir.calc_bounding_box).to eq(box)
        end

        it 'should calculate the bounding box of a set of points' do
          @resource.geolocations.each { |item| item.geolocation_box.destroy if item.geolocation_box }
          @resource.reload

          temp_ir = IndexingResource.new(resource: @resource)
          box = Datacite::Mapping::GeoLocationBox.new(37.0, -122.31, 41.23, -122.0)
          expect(temp_ir.calc_bounding_box).to eq(box)
        end

        it 'should calculate the bounding box of a combination of points and boxes' do
          box = Datacite::Mapping::GeoLocationBox.new(34.270836, -128.671875, 43.612217, -95.888672)
          expect(@ir.calc_bounding_box).to eq(box)
        end
      end

      describe '#dct_temporal_dates' do
        it 'gets those dates' do
          expect(@ir.dct_temporal_dates).to eql(['2018-11-14'])
        end
      end

      describe '#bounding_box_envelope' do
        it 'gives a set of numbers like SOLR or Geoblacklight likes' do
          expect(@ir.bounding_box_envelope).to eql('ENVELOPE(-128.671875, -95.888672, 43.612217, 34.270836)')
        end
      end

      describe '#to_index_document' do
        it 'creates the correct mega-hash for SOLR' do
          # all these attributes were created by other methods with minimal transformation by this method and mostly
          # just assembled into the mega-hash for SOLR
          mega_hash = @ir.to_index_document
          expected_mega_hash = {
            uuid: 'doi:10.1072/FK2something',
            dc_identifier_s: 'doi:10.1072/FK2something',
            dc_title_s: 'My test factory',
            dc_creator_sm: ['McVie, Gargcelia', 'Liu, Horace'],
            dc_type_s: 'Dataset',
            dc_description_s: 'Cat belowsquared',
            dc_subject_sm: ['freshwater cats', 'parsimonious'],
            dct_spatial_sm: %w[Oakland Timbuktu Greenland],
            georss_box_s: '34.270836 -128.671875 43.612217 -95.888672',
            solr_geom: 'ENVELOPE(-128.671875, -95.888672, 43.612217, 34.270836)',
            solr_year_i: 2018,
            dct_issued_dt: '2008-09-15T15:53:00Z',
            dc_rights_s: 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication',
            dc_publisher_s: 'Dryad',
            dct_temporal_sm: ['2018-11-14'],
            dryad_related_publication_name_s: 'Journal of Testing Fun'
          }
          expect(mega_hash).to eql(expected_mega_hash)
        end
      end
      # Note: private methods in this class end up being tested through other methods
    end
  end
end
