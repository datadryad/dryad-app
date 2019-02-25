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
        expect(review.title_str).to eq(resource.title)
      end

      it 'extracts the title string' do
        expect(review.title_str).to eq('A Zebrafish Model for Studies on Esophageal Epithelial Biology')
      end

      it 'extracts the resource type' do
        expect(review.resource_type).to eq(resource.resource_type)
      end

      it 'extracts the authors' do
        expect(review.authors).to eq(resource.authors)
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
        expect(review.geolocation_data?).to eq(true)
      end

      it 'identifies the absence of geolocation data' do
        resource.geolocations.to_a.each(&:destroy)
        @review = Review.new(resource)
        expect(review.geolocation_data?).to eq(false)
      end

      # TODO: figure out why
      it 'returns an unsaved embargo for resources with no embargo' do
        embargo = review.embargo
        expect(embargo).not_to be_nil
        expect(embargo.resource_id).to be_nil
        expect(embargo.persisted?).to eq(false)
      end

      it 'returns the resource embargo, if present' do
        embargo = StashEngine::Embargo.create(resource_id: resource.id, end_date: Date.today)
        resource.reload
        expect(review.embargo).to eq(embargo)
      end

      describe :pdf_filename do
        it 'includes author name and title' do
          pdf_filename = review.pdf_filename
          expect(pdf_filename).to include('Chen')
          expect(pdf_filename).to include('Zebrafish')
        end

        it 'includes publication year' do
          expect(review.pdf_filename).to include('2016')
        end

        it 'does not actually end in PDF' do # TODO: why not?
          expect(review.pdf_filename).not_to include('.pdf')
        end

        it 'adds "et al" for multi-author datasets' do
          StashEngine::Author.create(resource_id: resource.id, author_first_name: 'Elvis', author_last_name: 'Presley')
          resource.reload
          expect(review.pdf_filename).to include('Chen_et_al')
        end
      end
    end
  end
end
