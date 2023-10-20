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
        @user = StashEngine::User.create(
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )

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

        @tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                 account: 'stash',
                                                                 password: 'stash',
                                                                 id_scheme: 'doi')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:default_license).and_return('cc0')

        @metadata_entry = MetadataEntry.new(resource, 'dataset', tenant)
      end

      describe '#initialize' do
        it 'creates a license if needed' do
          resource.rights.clear
          @metadata_entry = MetadataEntry.new(resource, 'dataset', tenant)
          rights = resource.rights.first
          expect(rights).not_to be_nil
          expect(rights.rights).to eq('CC0 1.0 Universal (CC0 1.0) Public Domain Dedication')
          expect(rights.rights_uri).to eq('https://creativecommons.org/publicdomain/zero/1.0/')
        end

        it 'creates a publisher if needed' do
          resource.publisher = nil
          @metadata_entry = MetadataEntry.new(resource, 'dataset', tenant)
          publisher = metadata_entry.instance_variable_get(:@publisher)
          expect(publisher).to be_a(Publisher)
          expect(publisher.publisher).to eq('Dryad')
          expect(publisher.resource_id).to eq(resource.id)
        end
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

      describe '#abstract' do
        it 'extracts the abstract' do
          expect(metadata_entry.abstract).to eq(resource.descriptions.where(description_type: :abstract).first)
        end
      end

      describe '#methods' do
        it 'extracts the methods' do
          expect(metadata_entry.methods).to eq(resource.descriptions.where(description_type: :methods).first)
        end
      end

      describe '#other' do
        it 'extracts the "other" description' do
          expect(metadata_entry.other).to eq(resource.descriptions.where(description_type: :other).first)
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
