require 'db_spec_helper'

module StashEngine
  describe Resource do
    attr_reader :user

    before(:each) do
      @user = StashEngine::User.create(
        uid: 'lmuckenhaupt-ucop@ucop.edu',
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        provider: 'developer',
        tenant_id: 'ucop'
      )
    end

    describe 'uploads directory' do
      before(:each) do
        allow(Rails).to receive(:root).and_return('/apps/stash/stash_engine')
      end
      describe '#uploads_dir' do
        it 'returns the uploads directory' do
          expect(Resource.uploads_dir).to eq('/apps/stash/stash_engine/uploads')
        end
      end
      describe '#upload_dir_for' do
        it 'returns a separate directory by resource ID' do
          expect(Resource.upload_dir_for(17)).to eq('/apps/stash/stash_engine/uploads/17')
        end
      end
      describe '#upload_dir' do
        it 'returns the upload directory for this resource' do
          resource = Resource.create
          expect(resource.upload_dir).to eq("/apps/stash/stash_engine/uploads/#{resource.id}")
        end
      end
    end

    describe 'resource state' do
      attr_reader :resource
      attr_reader :state
      before(:each) do
        @resource = Resource.create(user_id: user.id)
        @state = ResourceState.find_by(resource_id: resource.id)
      end

      describe '#init_state' do
        it 'initializes the state to in_progress' do
          expect(state.resource_state).to eq('in_progress')
        end
        it 'sets the user ID' do
          expect(state.user_id).to eq(user.id)
        end
      end

      describe '#current_state=' do
        it 'sets the state' do
          new_state_value = 'published'
          resource.current_state = new_state_value
          new_state_id = resource.current_resource_state_id
          expect(new_state_id).not_to eq(state.id)
          new_state = ResourceState.find(new_state_id)
          expect(new_state.resource_state).to eq(new_state_value)
        end
      end

      describe '#current_resource_state' do
        it 'returns the initial state' do
          expect(state).not_to be_nil # just to be sure
          expect(resource.current_resource_state).to eq(state)
        end

        it 'reflects state changes' do
          %w(processing error embargoed published).each do |state_value|
            resource.current_state = state_value
            new_state = resource.current_resource_state
            new_state_id = new_state.id
            expect(new_state_id).not_to eq(state.id)
            expect(new_state.resource_state).to eq(state_value)
          end
        end
      end

      describe '#published?' do
        it 'returns true if the current state is published' do
          resource.current_state = 'published'
          expect(resource.published?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.published?).to eq(false)
          %w(in_progress processing error embargoed).each do |state_value|
            resource.current_state = state_value
            expect(resource.published?).to eq(false)
          end
        end
      end

      describe '#processing?' do
        it 'returns true if the current state is processing' do
          resource.current_state = 'processing'
          expect(resource.processing?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.processing?).to eq(false)
          %w(in_progress published error embargoed).each do |state_value|
            resource.current_state = state_value
            expect(resource.processing?).to eq(false)
          end
        end
      end

      describe '#current_resource_state_value' do
        it 'returns the value of the current state' do
          expect(resource.current_resource_state_value).to eq('in_progress')
          %w(processing error embargoed published).each do |state_value|
            resource.current_state = state_value
            expect(resource.current_resource_state_value).to eq(state_value)
          end
        end
      end
    end

    describe '#file_uploads' do
      attr_reader :temp_file_paths
      attr_reader :uploads
      attr_reader :resource

      before(:each) do
        @resource = Resource.create
        @temp_file_paths = Array.new(3) do |i|
          tempfile = Tempfile.new(["foo-#{i}", 'bin'])
          File.write(tempfile.path, '')
          tempfile.path
        end
        @uploads = temp_file_paths.map do |path|
          FileUpload.create(
            resource_id: resource.id,
            upload_file_name: File.basename(path),
            temp_file_path: path,
            file_state: :created
          )
        end
      end

      describe '#current_file_uploads' do
        it 'finds all non-deleted files' do
          (0...3).each do |i|
            FileUpload.create(
              resource_id: resource.id,
              upload_file_name: "missing-file-#{i}.bin",
              temp_file_path: "/missing-file-#{i}.bin",
              file_state: :deleted
            )
          end
          expect(FileUpload.where(resource_id: resource.id).count).to eq(6) # just to be sure
          current = resource.current_file_uploads
          expect(current.count).to eq(uploads.size)
          current.each { |upload| expect(uploads).to include(upload) }
        end
      end

      describe '#latest_file_states' do
        it 'finds the latest version of each file' do
          new_latest = uploads.each_with_index.map do |upload, i|
            FileUpload.create(
              resource_id: upload.resource_id,
              upload_file_name: upload.upload_file_name,
              temp_file_path: Tempfile.new(["foo-#{i}", 'bin']),
              file_state: :copied
            )
          end
          latest = resource.latest_file_states
          expect(latest.count).to eq(new_latest.size)
          latest.each { |upload| expect(new_latest).to include(upload) }
        end
      end

      describe '#clean_uploads' do
        it 'removes all upload records without files' do
          (0...3).each { |i| FileUpload.create(resource_id: resource.id, temp_file_path: "/missing-file-#{i}.bin", file_state: :created) }
          expect(FileUpload.where(resource_id: resource.id).count).to eq(6) # just to be sure
          resource.clean_uploads
          expect(FileUpload.where(resource_id: resource.id).count).to eq(3)
        end
      end
    end

    describe 'versioning' do
      attr_reader :resource
      before(:each) do
        @resource = Resource.create
      end

      describe '#stash_version' do
        it 'is initialized' do
          expect(resource.stash_version).not_to be_nil
        end
      end

      describe '#version_number' do
        it 'defaults to 1' do
          expect(resource.version_number).to eq(1)
        end
      end

      describe '#version_zipfile=' do
        it 'creates the first version' do
          zipfile = '/apps/stash/stash_engine/uploads/17-archive.zip'
          resource.version_zipfile = zipfile
          version = StashEngine::Version.find_by(resource_id: resource.id)
          expect(version).not_to be_nil
          expect(version.zip_filename).to eq('17-archive.zip')
          expect(version.version).to eq(1)
        end
      end

      describe 'identifier interaction' do
        before(:each) do
          doi_value = '10.1234/5678'
          resource.ensure_identifier("doi:#{doi_value}")
          # TODO: collapse this into single method on resource
          resource.current_state = 'published'
          resource.version_zipfile = "#{resource.id}-archive.zip"
        end

        describe '#version_number' do
          it 'still defaults to 1' do
            expect(resource.version_number).to eq(1)
          end

          it 'is incremented for the next resource by Amoeba duplication' do
            new_resource = resource.amoeba_dup
            new_resource.save!
            expect(new_resource.version_number).to eq(2)
          end

          it 'is incremented for the next resource' do
            new_resource = Resource.create(identifier: resource.identifier)
            expect(new_resource.version_number).to eq(2)
          end
        end

        describe '#next_version_number' do
          it 'is based on the last submitted version' do
            expect(resource.next_version_number).to eq(2)
          end
        end
      end
    end

    describe 'identifiers' do
      attr_reader :resource
      before(:each) do
        @resource = Resource.create(user_id: user.id)
      end
      describe '#ensure_identifier' do
        it 'defaults to nil' do
          expect(resource.identifier).to be_nil
        end

        it 'sets the identifier value' do
          doi_value = '10.12345/679810'
          resource.ensure_identifier(doi_value)
          ident = resource.identifier
          expect(ident).not_to be_nil
          expect(ident.identifier_type).to eq('DOI')
          expect(ident.identifier).to eq(doi_value)
        end

        it 'works with or without "doi:" prefix' do
          doi_value = '10.12345/679810'
          resource.ensure_identifier("doi:#{doi_value}")
          ident = resource.identifier
          expect(ident).not_to be_nil
          expect(ident.identifier_type).to eq('DOI')
          expect(ident.identifier).to eq(doi_value)
        end

        it 'raises an error if the resource already has a different identifier' do
          doi_value = '10.123/456'
          resource.ensure_identifier(doi_value)
          expect { resource.ensure_identifier('10.345/678') }.to raise_error(ArgumentError)
          expect(Identifier.count).to eq(1)
          expect(resource.identifier_value).to eq(doi_value)
        end

        it 'doesn\'t create extra identifier records' do
          doi_value = '10.123/456'
          existing_ident = Identifier.create(identifier: doi_value, identifier_type: 'DOI')
          (0..3).each do |_|
            resource.ensure_identifier(doi_value)
          end
          expect(Identifier.count).to eq(1)
          expect(resource.identifier).to eq(existing_ident)
        end
      end

      describe '#identifier_str' do
        it 'defaults to nil' do
          expect(resource.identifier_str).to be_nil
        end

        it 'returns the full DOI' do
          doi_value = '10.123/456'
          resource.ensure_identifier(doi_value)
          expect(resource.identifier_str).to eq("doi:#{doi_value}")
        end
      end

    end

    describe '#submission_to_repository' do
      attr_reader :resource
      attr_reader :logger
      attr_reader :tenant
      attr_reader :sword_params
      attr_reader :zipfile
      attr_reader :title
      attr_reader :doi
      attr_reader :request_host
      attr_reader :request_port

      before(:each) do
        allow(SwordJob).to receive(:submit_async)

        @resource = Resource.create(user_id: user.id)

        @logger = instance_double(Logger)
        allow(logger).to receive(:debug)

        @rails_logger = Rails.logger
        Rails.logger = logger

        @tenant = instance_double(Tenant)
        @sword_params = {collection_uri: 'http://sword.example.org/royal-society'}
        allow(tenant).to receive(:sword_params).and_return(sword_params)

        @zipfile = "#{resource.id}-archive.zip"
        @title = 'An Account of a Very Odd Monstrous Calf'
        @doi = 'doi:10.1098/rstl.1665.0007'
        @request_host = 'stash.example.org'
        @request_port = 80
      end

      after(:each) do
        Rails.logger = @rails_logger
      end

      it 'sets the DOI' do
        resource.submission_to_repository(tenant, zipfile, title, doi, request_host, request_port)
        expect(resource.identifier_str).to eq(doi)
      end

      it 'submits the job' do
        expect(SwordJob).to receive(:submit_async).with(
          title: title,
          doi: doi,
          zipfile: zipfile,
          resource_id: resource.id,
          sword_params: sword_params,
          request_host: request_host,
          request_port: request_port
        )
        resource.submission_to_repository(tenant, zipfile, title, doi, request_host, request_port)
      end
    end

    describe 'statistics' do
      describe '#submitted_dataset_count' do
        it 'defaults to zero' do
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'counts published current states' do
          (0...3).each do |index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'published'
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(3)
        end
        it 'groups by identifier' do
          (0...3).each do |index|
            res1 = Resource.create(user_id: user.id)
            res1.ensure_identifier('10.123/456')
            res1.current_state = 'published'
            res1.save

            res2 = Resource.create(user_id: user.id)
            res2.ensure_identifier('10.345/678')
            res2.current_state = 'published'
            res2.save
          end
          expect(Resource.submitted_dataset_count).to eq(2)
        end

        it 'doesn\'t count non-published datasets' do
          %w(in_progress processing error embargoed).each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'doesn\'t count non-current states' do
          %w(in_progress processing error embargoed).each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'published'
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
      end
    end

  end
end
