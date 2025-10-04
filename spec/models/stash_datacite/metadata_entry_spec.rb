module StashDatacite
  module Resource
    describe MetadataEntry do
      attr_reader :user
      attr_reader :stash_wrapper
      attr_reader :dcs_resource
      attr_reader :resource
      attr_reader :metadata_entry
      attr_reader :tenant

      before(:each) do
        @user = create(:user,
                       email: 'lmuckenhaupt@example.edu',
                       tenant_id: 'dataone')

        dc3_xml = File.read('spec/data/archive/mrt-datacite.xml')
        @dcs_resource = Datacite::Mapping::Resource.parse_xml(dc3_xml)
        stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        @stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

        @metadata_entry = MetadataEntry.new(resource, 'dataset', @user.tenant)
      end

      describe '#title' do
        it 'extracts the main title' do
          expect(metadata_entry.title).to eq(resource.title)
        end
      end

      describe '#resource_type' do
        it 'extracts the resource type' do
          expect(metadata_entry.resource_type).to eq(resource.resource_type)
        end
        it 'creates a resource type if not present' do
          resource.resource_type = nil
          new_type = metadata_entry.resource_type
          expect(new_type).to be_a(ResourceType)
          expect(new_type.resource_id).to eq(resource.id)
        end
      end

      describe '#authors' do
        it 'extracts the authors' do
          expect(metadata_entry.authors).to eq(resource.authors)
        end
      end

      describe '#subjects' do
        it 'extracts the subjects' do
          expect(metadata_entry.subjects).to eq(resource.subjects)
        end
      end

      describe '#contributors' do
        it 'extracts the contributors' do
          expect(metadata_entry.contributors).to eq(resource.contributors.where(contributor_type: :funder))
        end
      end

      describe '#related_identifiers' do
        it 'extracts the related identifiers' do
          expect(metadata_entry.related_identifiers).to eq(resource.related_identifiers)
        end
      end

      describe '#geolocation_points' do
        it 'extracts the geolocation points' do
          expect(metadata_entry.geolocation_points).to eq(GeolocationPoint.only_geo_points(resource.id))
        end
      end

      describe '#geolocation_boxes' do
        it 'extracts the geolocation boxes' do
          expect(metadata_entry.geolocation_boxes).to eq(GeolocationBox.only_geo_bbox(resource.id))
        end
      end

      describe '#geolocation_places' do
        it 'extracts the geolocation places' do
          expect(metadata_entry.geolocation_places).to eq(GeolocationPlace.from_resource_id(resource.id))
        end
      end

      describe 'new_author' do
        it 'creates a author' do
          author = metadata_entry.new_author
          expect(author).to be_a(StashEngine::Author)
          expect(author.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_subject' do
        it 'creates a subject' do
          subject = metadata_entry.new_subject
          expect(subject).to be_a(Subject)
          expect(subject.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_contributor' do
        it 'creates a contributor' do
          contributor = metadata_entry.new_contributor
          expect(contributor).to be_a(Contributor)
          expect(contributor.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_related_identifier' do
        it 'creates a related_identifier' do
          related_identifier = metadata_entry.new_related_identifier
          expect(related_identifier).to be_a(RelatedIdentifier)
          expect(related_identifier.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_geolocation_point' do
        it 'creates a geolocation_point' do
          geolocation_point = metadata_entry.new_geolocation_point
          expect(geolocation_point).to be_a(GeolocationPoint)
          expect(geolocation_point.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_geolocation_box' do
        it 'creates a geolocation_box' do
          geolocation_box = metadata_entry.new_geolocation_box
          expect(geolocation_box).to be_a(GeolocationBox)
          expect(geolocation_box.instance_variable_get(:@new_record)).to eq(true)
        end
      end

      describe 'new_geolocation_place' do
        it 'creates a geolocation_place' do
          geolocation_place = metadata_entry.new_geolocation_place
          expect(geolocation_place).to be_a(GeolocationPlace)
          expect(geolocation_place.instance_variable_get(:@new_record)).to eq(true)
        end
      end
    end
  end
end
