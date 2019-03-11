require 'db_spec_helper'

# briley - TODO StashEngine tests should live in stash_engine/spec. We should
#          not be testing functionality of other engines!

module StashEngine
  describe Resource do
    attr_reader :user

    attr_reader :future_date

    before(:all) do
      tomorrow = Date.today + 1
      @future_date = Date.new(tomorrow.year + 1, tomorrow.month, tomorrow.day)
    end

    before(:each) do
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'ucop'
      )
    end

    describe :tenant do
      it 'returns the resource tenant' do
        tenant = instance_double(Tenant)
        allow(Tenant).to receive(:find).with('ucop').and_return(tenant)

        resource = Resource.create(user_id: user.id, tenant_id: 'ucop')
        expect(resource.tenant).to eq(tenant)
        expect(user.tenant).to eq(tenant)
      end
    end

    describe :tenant_id do
      it 'returns the user tenant ID' do
        resource = Resource.create(user_id: user.id, tenant_id: 'ucop')
        expect(resource.tenant_id).to eq('ucop')
      end
    end

    describe 'Merrit-specific URL shenanigans' do
      describe :merritt_producer_download_uri do
        it 'returns the producer download URI' do
          download_uri = 'https://merritt.example.edu/d/ark%3A%2Fb5072%2Ffk2736st5z'
          resource = Resource.create(user_id: user.id)
          resource.download_uri = download_uri
          expect(resource.merritt_producer_download_uri).to eq('https://merritt.example.edu/u/ark%3A%2Fb5072%2Ffk2736st5z/1')
        end
      end

      # TODO: this shouldn't be in StashEngine
      describe :merritt_protodomain_and_local_id do
        it 'returns the merritt protocol and domain and local ID' do
          download_uri = 'https://merritt.example.edu/d/ark%3A%2Fb5072%2Ffk2736st5z'
          resource = Resource.create(user_id: user.id)
          resource.download_uri = download_uri

          merritt_protodomain, local_id = resource.merritt_protodomain_and_local_id
          expect(merritt_protodomain).to eq('https://merritt.example.edu')
          expect(local_id).to eq('ark%3A%2Fb5072%2Ffk2736st5z')
        end
      end
    end

    describe :dataset_in_progress_editor_id do
      it 'defaults to current_editor for no identifier' do
        resource = Resource.create(user_id: user.id, current_editor_id: 1)
        expect(resource.dataset_in_progress_editor_id).to eq(1)
      end

      it 'gives editor id of in progress version' do
        identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        resource1 = Resource.create(user_id: user.id, identifier_id: identifier.id, current_editor_id: 1)
        resource2 = Resource.create(user_id: user.id, identifier_id: identifier.id, current_editor_id: 2)
        state1 = ResourceState.create(user_id: 1, resource_state: 'submitted', resource_id: resource1.id)
        state2 = ResourceState.create(user_id: 2, resource_state: 'in_progress', resource_id: resource2.id)
        resource1.update(current_resource_state_id: state1.id)
        resource2.update(current_resource_state_id: state2.id)
        expect(resource1.dataset_in_progress_editor_id).to eq(2) # gives the in progress dataset's editor_id even though this one isn't in progress
        expect(resource2.dataset_in_progress_editor_id).to eq(2)
        resource2.delete
        expect(resource1.dataset_in_progress_editor_id).to eq(nil) # no in-progress should return a nil
      end

      it 'gives editor of in progress version' do
        user1 = User.create(tenant_id: 'ucop', first_name: 'Laura', last_name: 'Muckenhaupt')
        user2 = User.create(tenant_id: 'ucop', first_name: 'Gopher', last_name: 'Jones')
        identifier = Identifier.create(identifier: 'cat/dog', identifier_type: 'DOI')
        resource1 = Resource.create(user_id: user1.id, identifier_id: identifier.id, current_editor_id: user1.id)
        resource2 = Resource.create(user_id: user1.id, identifier_id: identifier.id, current_editor_id: user2.id)
        state1 = ResourceState.create(user_id: 1, resource_state: 'submitted', resource_id: resource1.id)
        state2 = ResourceState.create(user_id: 2, resource_state: 'in_progress', resource_id: resource2.id)
        resource1.update(current_resource_state_id: state1.id)
        resource2.update(current_resource_state_id: state2.id)
        expect(resource1.dataset_in_progress_editor.id).to eq(user2.id)
        expect(resource2.dataset_in_progress_editor.id).to eq(user2.id)
        resource2.delete
        expect(resource1.dataset_in_progress_editor.id).to eq(user1.id)
      end
    end

    describe :ensure_state_and_version do
      attr_reader :resource
      attr_reader :orig_state_id
      attr_reader :orig_version
      before(:each) do
        @resource = Resource.create(user_id: user.id)
        @orig_state_id = resource.current_resource_state_id
        @orig_version = resource.stash_version
      end

      it 'inits version if not present' do
        resource.stash_version.delete
        resource.stash_version = nil
        resource.ensure_state_and_version

        expect(resource.current_resource_state_id).to eq(orig_state_id) # shouldn't change

        expect(resource.stash_version).not_to be_nil
        expect(resource.stash_version).not_to eq(orig_version)
      end

      it 'inits state if not present' do
        resource.current_resource_state_id = nil
        resource.ensure_state_and_version

        expect(resource.stash_version).to eq(orig_version) # shouldn't change

        expect(resource.current_resource_state_id).not_to be_nil
        expect(resource.current_resource_state_id).not_to eq(orig_state_id)
      end
    end

    describe 'author' do
      attr_reader :resource
      before(:each) do
        @resource = Resource.create(user_id: user.id)
      end

      it 'defaults to no authors' do
        expect(resource.authors).to be_empty
      end

      it 'allows one author' do
        author = Author.create(
          resource_id: resource.id,
          author_first_name: 'Albert',
          author_last_name: 'Einstein',
          author_email: 'bigal@example.edu',
          author_orcid: '0000-0001-8528-2091'
        )
        expect(resource.authors.first).to eq(author)
      end

      it 'allows multiple authors' do
        author1 = Author.create(
          resource_id: resource.id,
          author_first_name: 'Lise',
          author_last_name: 'Meitner',
          author_email: 'lmeitner@example.edu',
          author_orcid: '0000-0003-4293-0137'
        )
        author2 = Author.create(
          resource_id: resource.id,
          author_first_name: 'Albert',
          author_last_name: 'Einstein',
          author_email: 'bigal@example.edu',
          author_orcid: '0000-0001-8528-2091'
        )
        expect(resource.authors).to include(author1, author2)
      end

      describe 'amoeba duplication' do
        attr_reader :authors

        before(:each) do
          @authors = [
            Author.create(
              resource_id: resource.id,
              author_first_name: 'Lise',
              author_last_name: 'Meitner',
              author_email: 'lmeitner@example.edu',
              author_orcid: '0000-0003-4293-0137'
            ),
            Author.create(
              resource_id: resource.id,
              author_first_name: 'Albert',
              author_last_name: 'Einstein',
              author_email: 'bigal@example.edu',
              author_orcid: '0000-0001-8528-2091'
            )
          ]
        end

        it 'copies authors' do
          old_authors = resource.authors.to_a
          expect(Author.count).to eq(2) # just to be sure
          expect(old_authors.size).to eq(2) # just to be sure

          new_resource = resource.amoeba_dup
          new_resource.save!
          expect(Author.count).to eq(4)

          new_authors = new_resource.authors.to_a
          expect(new_authors.size).to eq(2)
          new_authors.each_with_index do |author, i|
            expect(author.id).not_to eq(old_authors[i].id)
            expect(author.resource_id).to eq(new_resource.id)
            expect(author.author_first_name).to eq(old_authors[i].author_first_name)
            expect(author.author_last_name).to eq(old_authors[i].author_last_name)
            expect(author.author_email).to eq(old_authors[i].author_email)
            expect(author.author_orcid).to eq(old_authors[i].author_orcid)
          end
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

      describe :init_state do
        it 'initializes the state to in_progress' do
          expect(state.resource_state).to eq('in_progress')
        end
        it 'sets the user ID' do
          expect(state.user_id).to eq(user.id)
        end
      end

      describe :current_state= do
        it 'sets the state' do
          new_state_value = 'submitted'
          resource.current_state = new_state_value
          new_state = resource.current_resource_state
          expect(new_state.resource_state).to eq(new_state_value)
        end
        it 'doesn\'t create unnecesary values' do
          state = resource.current_resource_state
          expect(ResourceState.count).to eq(1)
          resource.current_state = 'in_progress'
          expect(ResourceState.count).to eq(1)
          expect(resource.current_resource_state).to eq(state)
        end
        describe 'amoeba duplication' do
          it 'defaults to in-progress' do
            resource.current_state = 'submitted'
            res1 = resource.amoeba_dup
            res1.save!
            expect(res1.current_state).to eq('in_progress')
          end
          it 'creates a new instance' do
            resource.current_state = 'submitted'
            res1 = resource.amoeba_dup
            res1.save!
            res1.current_state = 'error'
            expect(res1.current_state).to eq('error')
            expect(resource.current_state).to eq('submitted')
          end
        end
      end

      describe :current_resource_state do
        it 'returns the initial state' do
          expect(state).not_to be_nil # just to be sure
          expect(resource.current_resource_state).to eq(state)
        end

        it 'reflects state changes' do
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            new_state = resource.current_resource_state
            expect(new_state.resource_state).to eq(state_value)
          end
        end

        it 'is not copied or clobbered in Amoeba duplication' do
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            new_resource = resource.amoeba_dup
            new_resource.save!

            new_resource_state = new_resource.current_resource_state
            expect(new_resource_state.resource_id).to eq(new_resource.id)
            expect(new_resource_state.resource_state).to eq('in_progress')

            orig_resource_state = resource.current_resource_state
            expect(orig_resource_state.resource_id).to eq(resource.id)
            expect(orig_resource_state.resource_state).to eq(state_value)
          end
        end
      end

      describe :submitted? do
        it 'returns true if the current state is published' do
          resource.current_state = 'submitted'
          expect(resource.submitted?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.submitted?).to eq(false)
          %w[in_progress processing error].each do |state_value|
            resource.current_state = state_value
            expect(resource.submitted?).to eq(false)
          end
        end
      end

      describe :processing? do
        it 'returns true if the current state is processing' do
          resource.current_state = 'processing'
          expect(resource.processing?).to eq(true)
        end
        it 'returns false otherwise' do
          expect(resource.processing?).to eq(false)
          %w[in_progress submitted error].each do |state_value|
            resource.current_state = state_value
            expect(resource.processing?).to eq(false)
          end
        end
      end

      describe :current_state do
        it 'returns the value of the current state' do
          expect(resource.current_state).to eq('in_progress')
          %w[processing error submitted].each do |state_value|
            resource.current_state = state_value
            expect(resource.current_state).to eq(state_value)
          end
        end
      end
    end

    describe 'file uploads' do
      describe 'uploads directory' do
        before(:each) do
          allow(Rails).to receive(:root).and_return('/apps/stash/stash_engine')
        end
        describe :uploads_dir do
          it 'returns the uploads directory' do
            expect(Resource.uploads_dir).to eq('/apps/stash/stash_engine/uploads')
          end
        end
        describe :upload_dir_for do
          it 'returns a separate directory by resource ID' do
            expect(Resource.upload_dir_for(17)).to eq('/apps/stash/stash_engine/uploads/17')
          end
        end
        describe :upload_dir do
          it 'returns the upload directory for this resource' do
            resource = Resource.create
            expect(resource.upload_dir).to eq("/apps/stash/stash_engine/uploads/#{resource.id}")
          end
        end
      end

      describe :current_file_uploads do
        attr_reader :res1
        attr_reader :created_files
        attr_reader :copied_files
        attr_reader :deleted_files
        before(:each) do
          @res1 = Resource.create(user_id: user.id)

          @created_files = Array.new(3) do |i|
            FileUpload.create(
              resource: res1,
              file_state: 'created',
              upload_file_name: "created#{i}.bin",
              upload_file_size: i * 3
            )
          end
          @copied_files = Array.new(3) do |i|
            FileUpload.create(
              resource: res1,
              file_state: 'copied',
              upload_file_name: "copied#{i}.bin",
              upload_file_size: i * 5
            )
          end
          @deleted_files = Array.new(3) do |i|
            FileUpload.create(
              resource: res1,
              file_state: 'deleted',
              upload_file_name: "deleted#{i}.bin",
              upload_file_size: i * 7
            )
          end
        end

        it 'defaults to empty' do
          res2 = Resource.create(user_id: user.id)
          expect(res2.current_file_uploads).to be_empty
        end

        it 'includes created and copied' do
          current = res1.current_file_uploads
          created_files.each { |f| expect(current).to include(f) }
          copied_files.each { |f| expect(current).to include(f) }
          deleted_files.each { |f| expect(current).not_to include(f) }
        end

        describe 'amoeba duplication' do
          attr_reader :res2
          before(:each) do
            @res2 = res1.amoeba_dup
          end

          it 'copies the records' do
            expected_names = res1.file_uploads.map(&:upload_file_name)
            actual_names = res2.file_uploads.map(&:upload_file_name)
            expect(actual_names).to contain_exactly(*expected_names)
          end

          it 'copies all current records' do
            old_current_names = res1.current_file_uploads.map(&:upload_file_name)
            new_current_names = res2.current_file_uploads.map(&:upload_file_name)
            expect(new_current_names).to contain_exactly(*old_current_names)
          end

          it 'sets all current records to "copied"' do
            res2.current_file_uploads.each { |f| expect(f.file_state).to eq('copied') }
          end

          it 'doesn\'t copy deleted files' do
            expect(res2.file_uploads.deleted).to be_empty
          end
        end

        describe :size do
          it 'includes all copied and created' do
            created_size = created_files.inject(0) { |sum, f| sum + f.upload_file_size }
            copied_size = copied_files.inject(0) { |sum, f| sum + f.upload_file_size }
            expected_size = created_size + copied_size
            expect(res1.size).to eq(expected_size)
          end
        end

        describe :upload_type do
          it 'returns :unknown for no uploads' do
            res1.file_uploads.delete_all
            expect(res1.upload_type).to eq(:unknown)
          end

          it 'returns :files for files' do
            expect(res1.upload_type).to eq(:files)
          end

          it 'returns :manifest if at least one new file has a URL' do
            a_file = created_files[2]
            a_file.url = 'http://example.org/foo.bar'
            a_file.status_code = 200
            a_file.save

            expect(res1.upload_type).to eq(:manifest)
          end
        end

        describe :new_file_uploads do
          it 'defaults to empty' do
            res2 = Resource.create(user_id: user.id)
            expect(res2.new_file_uploads).to be_empty
          end

          it 'includes only created' do
            new = res1.new_file_uploads
            created_files.each { |f| expect(new).to include(f) }
            copied_files.each { |f| expect(new).not_to include(f) }
            deleted_files.each { |f| expect(new).not_to include(f) }
          end
        end
      end

      describe :file_uploads do
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

        describe :latest_file_states do
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

        describe :clean_uploads do
          it 'removes all upload records without files' do
            (0...3).each { |i| FileUpload.create(resource_id: resource.id, temp_file_path: "/missing-file-#{i}.bin", file_state: :created) }
            expect(FileUpload.where(resource_id: resource.id).count).to eq(6) # just to be sure
            resource.clean_uploads
            expect(FileUpload.where(resource_id: resource.id).count).to eq(3)
          end
        end

        describe :duplicate_filenames do
          it 'identifies duplicate files' do
            original = uploads[0]
            file_name = original.upload_file_name
            duplicate = FileUpload.create(
              resource_id: resource.id,
              upload_file_name: file_name,
              temp_file_path: temp_file_paths[0].sub('.bin', '-1.bin'),
              file_state: :created
            )
            duplicates = resource.duplicate_filenames
            expect(duplicates.count).to eq(2)
            expect(duplicates).to include(original)
            expect(duplicates).to include(duplicate)
          end
        end

        describe :url_in_version? do
          it 'returns false if not present' do
            expect(resource.url_in_version?('http://example.org/')).to eq(false)
          end

          it 'returns true if present' do
            upload = uploads[0]
            upload.url = 'http://example.org/'
            upload.status_code = 200
            upload.save

            expect(resource.url_in_version?('http://example.org/')).to eq(true)
          end
        end
      end
    end

    describe 'versioning' do
      attr_reader :resource
      before(:each) do
        @resource = Resource.create
      end

      describe :stash_version do
        it 'is initialized' do
          expect(resource.stash_version).not_to be_nil
        end
      end

      describe :version_number do
        it 'defaults to 1' do
          expect(resource.version_number).to eq(1)
        end
      end

      describe :merritt_version do
        it 'defaults to 1' do
          expect(resource.merritt_version).to eq(1)
        end
      end

      describe :version_zipfile= do
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
          resource.current_state = 'submitted'
          resource.version_zipfile = "#{resource.id}-archive.zip"
        end

        describe :version_number do
          it 'still defaults to 1' do
            expect(resource.version_number).to eq(1)
          end

          it 'is incremented for the next resource by Amoeba duplication' do
            new_resource = resource.amoeba_dup
            new_resource.save!
            expect(new_resource.version_number).to eq(2)

            newer_resource = new_resource.amoeba_dup
            newer_resource.save!
            expect(newer_resource.version_number).to eq(2)
          end

          it 'is incremented for the next resource' do
            new_resource = Resource.create(identifier: resource.identifier)
            expect(new_resource.version_number).to eq(2)
          end
        end

        describe :merritt_version do
          it 'still defaults to 1' do
            expect(resource.merritt_version).to eq(1)
          end

          it 'is incremented for the next resource by Amoeba duplication' do
            new_resource = resource.amoeba_dup
            new_resource.save!
            expect(new_resource.merritt_version).to eq(2)
          end

          it 'is incremented for the next resource' do
            new_resource = Resource.create(identifier: resource.identifier)
            expect(new_resource.merritt_version).to eq(2)
          end
        end

        describe :next_version_number do
          it 'is based on the last submitted version' do
            expect(resource.next_version_number).to eq(2)
          end
        end

        describe :next_merritt_version do
          it 'is based on the last submitted version' do
            expect(resource.next_merritt_version).to eq(2)
          end
        end

        describe :latest_per_dataset do
          it 'only returns latest resources and new resources' do
            resource.dup.save
            Resource.create
            expect(Resource.latest_per_dataset.count).to eq(2)
          end
        end
      end
    end

    describe 'identifiers' do
      attr_reader :resource
      before(:each) do
        @resource = Resource.create(user_id: user.id)
      end

      describe :ensure_identifier do
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

      describe :identifier_str do
        it 'defaults to nil' do
          expect(resource.identifier_str).to be_nil
        end

        it 'returns the full DOI' do
          doi_value = '10.123/456'
          resource.ensure_identifier(doi_value)
          expect(resource.identifier_str).to eq("doi:#{doi_value}")
        end
      end

      describe :identifier_uri do
        it 'defaults to nil' do
          expect(resource.identifier_uri).to be_nil
        end

        it 'returns the doi.org URL' do
          doi_value = '10.123/456'
          resource.ensure_identifier(doi_value)
          expect(resource.identifier_uri).to eq("https://doi.org/#{doi_value}")
        end
      end

      describe 'amoeba duplication' do
        it 'preserves the identifier' do
          doi_value = '10.12345/679810'
          resource.ensure_identifier(doi_value)
          res2 = resource.amoeba_dup
          expect(res2.identifier_str).to eq("doi:#{doi_value}")
        end
      end
    end

    describe 'statistics' do
      describe :submitted_dataset_count do
        it 'defaults to zero' do
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'counts published current states' do
          (0...3).each do |index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'submitted'
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(3)
        end
        it 'groups by identifier' do
          (0...3).each do |_index|
            res1 = Resource.create(user_id: user.id)
            res1.ensure_identifier('10.123/456')
            res1.current_state = 'submitted'
            res1.save

            res2 = Resource.create(user_id: user.id)
            res2.ensure_identifier('10.345/678')
            res2.current_state = 'submitted'
            res2.save
          end
          expect(Resource.submitted_dataset_count).to eq(2)
        end

        it 'doesn\'t count non-published datasets' do
          %w[in_progress processing error].each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
        it 'doesn\'t count non-current states' do
          %w[in_progress processing error].each_with_index do |state, index|
            resource = Resource.create(user_id: user.id)
            resource.ensure_identifier("10.123/#{index}")
            resource.current_state = 'submitted'
            resource.current_state = state
            resource.save
          end
          expect(Resource.submitted_dataset_count).to eq(0)
        end
      end
    end
  end
end
