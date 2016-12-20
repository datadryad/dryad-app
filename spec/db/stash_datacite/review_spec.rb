require 'db_spec_helper'

module StashDatacite
  module Resource
    describe Review do
      attr_reader :user
      attr_reader :stash_wrapper
      attr_reader :dcs_resource
      attr_reader :resource
      attr_reader :review

      before(:all) do
        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )

        dc3_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(dc3_xml)
        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        @stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)
      end

      before(:each) do
        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

        @review = Review.new(resource)
      end

      it 'extracts the main title' do
        expect(review.title).to eq(resource.titles.where(title_type: nil).first)
      end

      it 'extracts the resource type' do
        expect(review.resource_type).to eq(resource.resource_type)
      end

      it 'extracts the creators' do
        expect(review.creators).to eq(resource.creators)
      end

      it 'extracts the version' do
        expect(review.version).to eq(resource.stash_version)
      end

      it 'extracts the identifier' do
        expect(review.identifier).to eq(resource.identifier)
      end

      it 'extracts the abstract' do
        expect(review.abstract).to eq(resource.descriptions.where(description_type: :abstract).first)
      end

      it 'extracts the methods' do
        expect(review.methods).to eq(resource.descriptions.where(description_type: :methods).first)
      end

      it 'extracts the "other" description' do
        expect(review.other).to eq(resource.descriptions.where(description_type: :other).first)
      end

      it 'extracts the subjects' do
        expect(review.subjects).to eq(resource.subjects)
      end

      it 'extracts the contributors' do
        expect(review.contributors).to eq(resource.contributors.where(contributor_type: :funder))
      end

      it 'extracts the related identifiers' do
        expect(review.related_identifiers).to eq(resource.related_identifiers)
      end

      it 'extracts the file uploads' do
        expect(review.file_uploads).to eq(resource.current_file_uploads)
      end

      it 'extracts the geolocation points' do
        expect(review.geolocation_points).to eq(GeolocationPoint.only_geo_points(resource.id))
      end

      it 'extracts the geolocation boxes' do
        expect(review.geolocation_boxes).to eq(GeolocationBox.only_geo_bbox(resource.id))
      end

      it 'extracts the geolocation places' do
        expect(review.geolocation_places).to eq(GeolocationPlace.from_resource_id(resource.id))
      end

      it 'extracts the publisher' do
        expect(review.publisher).to eq(resource.publisher)
      end

      it 'identifies the presence of geolocation data' do
        expect(review.no_geolocation_data).to eq(false)
      end

      it 'identifies the absence of geolocation data' do
        resource.geolocations.to_a.each(&:destroy)
        @review = Review.new(resource)
        expect(review.no_geolocation_data).to eq(true)
      end
    end
  end
end
