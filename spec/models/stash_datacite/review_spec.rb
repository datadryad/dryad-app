module StashDatacite
  module Resource
    describe Review do

      before(:each) do
        user = create(:user,
                      email: 'lmuckenhaupt@example.edu',
                      tenant_id: 'dataone')

        @resource = create(:resource, user: user)
        @review = Review.new(@resource)
      end

      it 'extracts the main title' do
        expect(@review.title_str).to eq(@resource.title)
      end

      it 'extracts the resource type' do
        expect(@review.resource_type).to eq(@resource.resource_type)
      end

      it 'extracts the authors' do
        expect(@review.authors).to eq(@resource.authors)
      end

      it 'extracts the version' do
        expect(@review.version).to eq(@resource.stash_version)
      end

      it 'extracts the identifier' do
        expect(@review.identifier).to eq(@resource.identifier)
      end

      it 'extracts the abstract' do
        expect(@review.abstract).to eq(@resource.descriptions.where(description_type: :abstract).first)
      end

      it 'extracts the methods' do
        expect(@review.methods).to eq(@resource.descriptions.where(description_type: :methods).first)
      end

      it 'extracts the "other" description' do
        expect(@review.other).to eq(@resource.descriptions.where(description_type: :other).first)
      end

      it 'extracts the subjects' do
        # They may be in different order
        @review.subjects.each do |subj|
          expect(@resource.subjects).to include(subj)
        end
        @resource.subjects.each do |subj|
          expect(@review.subjects).to include(subj)
        end
      end

      it 'extracts the contributors' do
        expect(@review.contributors).to eq(@resource.contributors.where(contributor_type: :funder))
      end

      it 'extracts the related identifiers' do
        expect(@review.related_identifiers).to eq(@resource.related_identifiers)
      end

      it 'extracts the file uploads' do
        expect(@review.file_uploads).to eq(@resource.current_file_uploads)
      end

      it 'extracts the geolocation points' do
        expect(@review.geolocation_points).to eq(GeolocationPoint.only_geo_points(@resource.id))
      end

      it 'extracts the geolocation boxes' do
        expect(@review.geolocation_boxes).to eq(GeolocationBox.only_geo_bbox(@resource.id))
      end

      it 'extracts the geolocation places' do
        expect(@review.geolocation_places).to eq(GeolocationPlace.from_resource_id(@resource.id))
      end

      it 'extracts the publisher' do
        expect(@review.publisher).to eq(@resource.publisher)
      end

      it 'identifies the presence of geolocation data' do
        place = create(:geolocation_place)
        point = create(:geolocation_point)
        box = create(:geolocation_box)
        create(:geolocation, place_id: place.id, point_id: point.id, box_id: box.id, resource_id: @resource.id)
        @review = Review.new(@resource)
        expect(@review.geolocation_data?).to eq(true)
      end

      it 'identifies the absence of geolocation data' do
        @resource.geolocations.to_a.each(&:destroy)
        @review = Review.new(@resource)
        expect(@review.geolocation_data?).to eq(false)
      end

      it 'returns the resource embargo, if present' do
        embargo = DateTime.now.utc.iso8601
        @resource.update(publication_date: embargo)
        @resource.reload
        expect(@review.embargo).to eq(embargo)
      end

      it 'calls current file uploads for supp_files' do
        expect(@resource).to receive(:current_file_uploads).with(my_class: StashEngine::SuppFile)
        @review.supp_files
      end
    end
  end
end
