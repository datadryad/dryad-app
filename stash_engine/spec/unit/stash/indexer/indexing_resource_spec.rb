require 'spec_helper'
require 'ostruct'
require 'datacite/mapping'

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
      before :each do
        #         id = Identifier.new(value: '10.14749/1407399495')
        #         creators = [
        #             Creator.new(
        #                 name: 'Hedy Lamarr',
        #                 identifier: NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-1690-159X'),
        #                 affiliations: ['United Artists', 'Metro-Goldwyn-Mayer']
        #             ),
        #             Creator.new(
        #                 name: 'Herschlag, Natalie',
        #                 identifier: NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-0907-8419'),
        #                 affiliations: ['Gaumont Buena Vista International', '20th Century Fox']
        #             )
        #         ]
        #         titles = [
        #             Title.new(value: 'An Account of a Very Odd Monstrous Calf', language: 'en-emodeng'),
        #             Title.new(type: TitleType::SUBTITLE, value: 'And a Contest between Twsts about Optick Glasses, &c', language: 'en-emodeng')
        #         ]
        #         publisher = 'California Digital Library'
        #         pub_year = 2015
        #
        #         @resource = Resource.new(
        #             identifier: id,
        #             creators: creators,
        #             titles: titles,
        #             publisher: publisher,
        #             publication_year: pub_year
        #         )
      end

      describe '#grant_number' do
        xit 'extracts the grant number' do
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          @resource.descriptions << other_desc

          funder = 'the Ministry of Magic'
          grant = '319995'
          funding_desc = Description.new(type: DescriptionType::OTHER, value: "Data were created with funding from #{funder} under grant #{grant}.")
          @resource.descriptions << funding_desc
          expect(@resource.grant_number).to eq(grant)
        end

        xit 'returns nil if no descriptions' do
          expect(@resource.grant_number).to be_nil
        end

        xit 'returns nil if no grant number found' do
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          @resource.descriptions << other_desc
          expect(@resource.grant_number).to be_nil
        end
      end

      describe '#usage_notes?' do
        xit 'extracts the usage notes' do
          usage_desc = Description.new(type: DescriptionType::OTHER, value: 'Some other value')
          @resource.descriptions << usage_desc
          expect(@resource.usage_notes).to eq(usage_desc.value)
        end
      end

      describe 'geo_location helpers' do
        before(:each) do
          #           @box1 = GeoLocationBox.new(16.31591, 73.480431, 22.672657, 83.068985)
          #           @box2 = GeoLocationBox.new(-33.45, -122.33, 47.61, -70.67)
          #           @point1 = GeoLocationPoint.new(-47.61, -70.67)
          #           @point2 = GeoLocationPoint.new(-33.45, -122.33)
          #           @place1 = 'Pacific Ocean'
          #           @place2 = 'Ouagadougou'
          #           @place_point1 = GeoLocationPoint.new(-48.8767, -123.3933)
          #           @place_point2 = GeoLocationPoint.new(12.3572, -1.5353)
          #           allow(@resource).to receive(:geo_locations) do
          #             [
          #                 GeoLocation.new(box: @box1),
          #                 GeoLocation.new(point: @point1),
          #                 GeoLocation.new(place: @place1, point: @place_point1),
          #                 GeoLocation.new(box: @box2),
          #                 GeoLocation.new(point: @point2),
          #                 GeoLocation.new(place: @place2, point: @place_point2)
          #             ]
          #           end
        end

        describe '#geo_location_boxes' do
          xit 'should extract the boxes' do
            expect(@resource.geo_location_boxes).to eq([@box1, @box2])
          end
        end

        describe '#geo_location_points' do
          xit 'should extract the points' do
            expect(@resource.geo_location_points).to contain_exactly(@point1, @point2, @place_point1, @place_point2)
          end
        end

        describe '#geo_location_places' do
          xit 'should extract the places' do
            expect(@resource.geo_location_places).to eq([@place1, @place2])
          end
        end
      end

      describe '#calc_bounding_box' do
        xit 'should calculate the bounding box of a box as itself' do
          box = GeoLocationBox.new(16.31591, 73.480431, 22.672657, 83.068985)
          allow(@resource).to receive(:geo_locations) { [GeoLocation.new(box: box)] }
          expect(@resource.calc_bounding_box).to eq(box)
        end

        xit 'should calculate the bounding box of a set of points' do
          box = GeoLocationBox.new(16.31591, 73.480431, 22.672657, 83.068985)
          points = [
            GeoLocationPoint.new(16.31591, 80),
            GeoLocationPoint.new(20, 73.480431),
            GeoLocationPoint.new(22.672657, 78),
            GeoLocationPoint.new(18, 83.068985)
          ]
          allow(@resource).to receive(:geo_locations) do
            points.map { |point| GeoLocation.new(point: point) }
          end
          expect(@resource.calc_bounding_box).to eq(box)
        end

        xit 'should calculate the bounding box of a combination of points and boxes' do
          allow(@resource).to receive(:geo_locations) do
            [
              GeoLocation.new(point: GeoLocationPoint.new(16.31591, 80)),
              GeoLocation.new(point: GeoLocationPoint.new(20, 83.068985)),
              GeoLocation.new(box: GeoLocationBox.new(18, 73.480431, 22.672657, 78))
            ]
          end
          box = GeoLocationBox.new(16.31591, 73.480431, 22.672657, 83.068985)
          expect(@resource.calc_bounding_box).to eq(box)
        end

        xit 'should include place points and boxes' do
          allow(@resource).to receive(:geo_locations) do
            [
              GeoLocation.new(point: GeoLocationPoint.new(16.31591, 80)),
              GeoLocation.new(place: 'Pacific Ocean', point: GeoLocationPoint.new(-48.8767, -123.3933)),
              GeoLocation.new(point: GeoLocationPoint.new(20, 83.068985)),
              GeoLocation.new(place: 'Ouagadougou', box: GeoLocationBox.new(18, 73.480431, 22.672657, 78))
            ]
          end
          box = GeoLocationBox.new(-48.8767, -123.3933, 22.672657, 83.068985)
          expect(@resource.calc_bounding_box).to eq(box)
        end
      end
    end
  end
end
