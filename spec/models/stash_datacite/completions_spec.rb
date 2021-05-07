module StashDatacite
  module Resource
    describe Completions do
      REQUIRED_FIELDS = ['title', 'author affiliation', 'author name', 'abstract', 'author email'].freeze
      REQUIRED_COUNT = REQUIRED_FIELDS.size

      OPTIONAL_FIELDS = ['date', 'keywords', 'methods', 'related identifiers'].freeze
      OPTIONAL_COUNT = OPTIONAL_FIELDS.size

      attr_reader :resource
      attr_reader :completions

      before(:each) do
        @user = create(:user)
        @resource = create(:resource, user: @user)
        @resource.save
        create(:resource_type, resource: @resource)
        create(:author, resource: @resource)
        create(:author, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        @resource.reload
        @completions = Completions.new(@resource)
      end

      describe :title do
        it 'passes for resources with titles' do
          expect(completions.title).to be_truthy
        end

        it 'fails if title is missing' do
          resource.title = ''
          expect(completions.title).to be_falsey
        end
      end

      describe :institution do
        it 'passes for resources with author affiliations' do
          expect(completions.institution).to be_truthy
        end

        it 'fails if author affiliation is missing' do
          resource.authors.flat_map(&:affiliations).each(&:destroy)
          expect(completions.institution).to be_falsey
        end
      end

      describe :data_type do
        it 'passes for resources with a type' do
          expect(completions.data_type).to be_truthy
        end

        it 'fails if type is missing' do
          resource.resource_type.destroy
          resource.reload # ActiveRecord is not smart enough to check 'destroyed' flag
          expect(completions.data_type).to be_falsey
        end
      end

      describe :article_id do
        before(:each) do
          @identifier = double(StashEngine::Identifier)
          allow(@resource).to receive(:identifier).and_return(@identifier)
        end

        it 'passes if journal name is omitted' do
          allow(@identifier).to receive(:publication_name).and_return(nil)
          expect(completions.article_id).to be_truthy
        end

        it 'fails if journal name is present, but manuscript number and DOI are not' do
          allow(@identifier).to receive(:publication_name).and_return('abc')
          allow(@identifier).to receive(:manuscript_number).and_return(nil)
          allow(@identifier).to receive(:publication_article_doi).and_return(nil)
          expect(completions.article_id).to be_falsey
        end

        it 'passes if journal name is present, along with a manuscript number' do
          allow(@identifier).to receive(:publication_name).and_return('abc')
          allow(@identifier).to receive(:manuscript_number).and_return('def')
          allow(@identifier).to receive(:publication_article_doi).and_return(nil)
          expect(completions.article_id).to be_truthy
        end
      end

      describe :author_name do
        it 'passes if all authors have first names' do
          expect(completions.author_name).to be_truthy
        end
        it 'fails if some authors don\'t have first names' do
          author = resource.authors.first
          author.author_first_name = nil
          author.save
          expect(completions.author_name).to be_falsey
        end
        it 'fails if author is missing' do
          resource.authors.each(&:destroy)
          expect(completions.author_name).to be_falsey
        end
      end

      describe :author_affiliation do
        it 'fails if author is missing' do
          resource.authors.each(&:destroy)
          expect(completions.author_affiliation).to be_falsey
        end

        it 'passes for resources with author affiliations' do
          expect(completions.author_affiliation).to be_truthy
        end

        it 'fails if author affiliation is missing' do
          @resource.authors.flat_map(&:affiliations).each(&:destroy)
          @resource.reload
          expect(completions.author_affiliation).to be_falsey
        end
      end

      describe :author_email do
      end

      describe :abstract do
        it 'passes for resources with abstracts' do
          expect(completions.abstract).to be_truthy
        end
        it 'passes for resources with no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no abstracts' do
          resource.descriptions.where(description_type: 'abstract').each(&:destroy)
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no non-nil abstracts' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = nil
            abstract.save
          end
          expect(completions.abstract).to be_falsey
        end
        it 'passes for resources with no non-blank abstracts' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = ''
            abstract.save
          end
          expect(completions.abstract).to be_falsey
        end
      end

      describe :urls_validated do
        describe ':manifest uploads' do
          before(:each) do
            @resource.data_files.find_each do |upload|
              upload.url = "http://example.org/#{upload.upload_file_name}"
              upload.save!
            end
          end

          it 'returns true when no files are newly created' do
            new_files = resource.data_files.newly_created
            new_files.find_each do |upload|
              upload.file_state = :copied
              upload.save!
            end
            expect(new_files).to be_empty # just to be sure
            expect(completions.urls_validated?).to eq(true)
          end

          it 'returns true when all newly created files are valid' do
            resource.data_files.newly_created.find_each do |upload|
              upload.status_code = 200
              upload.save!
            end
            expect(completions.urls_validated?).to eq(true)
          end

          it 'returns false when at least one newly created file has an error' do
            upload = resource.data_files.take
            upload.status_code = 403
            upload.save!
            expect(completions.urls_validated?).to eq(false)
          end

          it 'returns false when at least one Zenodo file has an error' do
            # good uploads for dataset
            resource.data_files.newly_created.find_each do |upload|
              upload.status_code = 200
              upload.save!
            end

            # bad upload for zenodo
            resource.software_files << create(:software_file, status_code: 411, url: 'https://happy.clown.example.com')

            @completions = Completions.new(resource) # refresh the completions object since I changed it
            expect(completions.urls_validated?).to eq(false)
          end
        end

        describe 'file uploads' do
          it 'returns true for non-manifest uploads' do
            expect(completions.urls_validated?).to eq(true)
          end
        end
      end

      describe :s3_error_uploads do

        it 'verifies uploads to s3 are present' do
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(true)
          end
          expect(completions.s3_error_uploads).to eq([])
        end

        it 'returns missing files when files uploaded to s3 are not present' do
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end
          expect(completions.s3_error_uploads).to eq(@resource.generic_files.map(&:upload_file_name))
        end

        it 'does not check missing files once Merritt processing is complete' do
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end
          allow(@resource).to receive('submitted?').and_return(true)
          expect(completions.s3_error_uploads).to be(nil)
        end

        it 'only checks files that are new uploads and are not urls' do
          @resource.generic_files.first.update(file_state: 'copied')
          @resource.generic_files.second.update(url: 'http://example.com')
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end
          expect(completions.s3_error_uploads).to eq([@resource.generic_files.last.upload_file_name])
        end
      end

      describe :over_manifest_file_size? do
        attr_reader :actual_size

        before(:each) do
          @actual_size = resource
            .data_files
            .present_files
            .inject(0) { |sum, f| sum + f.upload_file_size }
        end

        it 'returns true if file size > limit' do
          limit = actual_size - 1
          expect(completions.over_manifest_file_size?(limit)).to eq(true)
        end

        it 'returns false if file size <= limit' do
          limit = actual_size
          expect(completions.over_manifest_file_size?(limit)).to eq(false)
        end

        it 'counts copied files as well as new uploads' do
          resource.data_files.present_files.to_a.each_with_index do |f, index|
            if index.even?
              f.file_state = :copied
              f.save!
            end
            limit = actual_size - 1
            expect(completions.over_manifest_file_size?(limit)).to eq(true)
          end
        end
      end

      describe :over_version_size? do
        attr_reader :actual_size

        before(:each) do
          @actual_size = @resource.data_files.present_files.inject(0) { |sum, f| sum + f.upload_file_size }
        end

        it 'returns true if file size > limit' do
          limit = @actual_size - 1
          expect(completions.over_version_size?(limit)).to eq(true)
        end

        it 'returns false if file size <= limit' do
          limit = actual_size
          expect(completions.over_version_size?(limit)).to eq(false)
        end
      end

      describe :over_manifest_file_count? do
        attr_reader :actual_count
        before(:each) do
          @actual_count = resource.data_files.present_files.count
        end
        it 'returns true if file count > limit' do
          limit = actual_count - 1
          expect(completions.over_manifest_file_count?(limit)).to eq(true)
        end

        it 'returns false if file count <= limit' do
          limit = actual_count
          expect(completions.over_manifest_file_count?(limit)).to eq(false)
        end

        it 'counts copied files as well as new uploads' do
          resource.data_files.present_files.to_a.each_with_index do |f, index|
            if index.even?
              f.file_state = :copied
              f.save!
            end
            limit = actual_count - 1
            expect(completions.over_manifest_file_count?(limit)).to eq(true)
          end
        end
      end

      describe :required_total do
        it "counts all of: #{REQUIRED_FIELDS.join(', ')}" do
          expect(completions.required_total).to eq(REQUIRED_COUNT)
        end
      end

      describe :required_completed do
        it "returns a full count for resources with all of: #{REQUIRED_FIELDS.join(', ')}" do
          expect(completions.required_completed).to eq(REQUIRED_COUNT)
        end

        it 'counts if title is missing' do
          resource.title = ''
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'counts if affiliation is missing' do
          @resource.authors.flat_map(&:affiliations).each(&:destroy)
          @resource.reload
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'triple-counts (author, name, and email) if author is missing' do
          resource.authors.each(&:destroy)
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 3)
        end

        it 'counts if author name is missing' do
          author = resource.authors.first
          author.author_first_name = nil
          author.save
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end

        it 'counts if description is missing' do
          resource.descriptions.each(&:destroy)
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract is missing' do
          resource.descriptions.where(description_type: 'abstract').each(&:destroy)
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract text is nil' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = nil
            abstract.save
          end
          expect(completions.required_completed).to  eq(REQUIRED_COUNT - 1)
        end

        it 'counts if abstract text is blank' do
          resource.descriptions.where(description_type: 'abstract').each do |abstract|
            abstract.description = ''
            abstract.save
          end
          expect(completions.required_completed).to eq(REQUIRED_COUNT - 1)
        end
      end

      describe :date do
        before(:each) do
          create(:datacite_date, resource: @resource)
        end

        it 'passes if resource has a date' do
          expect(completions.date).to be_truthy
        end
        it 'fails if resource has no date' do
          resource.datacite_dates.each(&:destroy)
          expect(completions.date).to be_falsey
        end
      end

      describe :keyword do
        it 'passes if resource has subjects' do
          @resource.subjects = [create(:subject)]
          expect(completions.keyword).to be_truthy
        end
        it 'fails if resource has no subjects' do
          resource.subjects.clear
          expect(completions.keyword).to be_falsey
        end
        it 'fails if resource has no non-nil subjects' do
          resource.subjects.each do |subj|
            subj.subject = nil
            subj.save
          end
          expect(completions.keyword).to be_falsey
        end
        it 'fails if resource has no non-blank subjects' do
          resource.subjects.each do |subj|
            subj.subject = ''
            subj.save
          end
          expect(completions.keyword).to be_falsey
        end
      end

      describe :method do
        before(:each) do
          Description.create(
            description: 'some methods',
            description_type: 'methods',
            resource_id: resource.id
          )
        end
        it 'passes for resources with methods' do
          expect(completions.method).to be_truthy
        end
        it 'fails for resources with no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no methods' do
          resource.descriptions.where(description_type: 'methods').each(&:destroy)
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no non-nil methods' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = nil
            methods.save
          end
          expect(completions.method).to be_falsey
        end
        it 'fails for resources with no non-blank methods' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = ''
            methods.save
          end
          expect(completions.method).to be_falsey
        end
      end

      describe :related_works do
        before(:each) do
          create(:related_identifier, resource: @resource, related_identifier: Faker::Pid.doi,
                                      related_identifier_type: 'doi', relation_type: 'cites',
                                      work_type: 'article', verified: true)
        end

        it 'returns true if resource has related identifiers' do
          expect(completions.has_related_works?).to be_truthy
        end

        it 'returns false if resource has no related identifiers' do
          resource.related_identifiers.each(&:destroy)
          expect(completions.has_related_works?).to be_falsey
        end

        it 'returns false if resource has no non-nil related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = nil
            rel_ident.save
          end
          expect(completions.has_related_works?).to be_falsey
        end

        it 'returns false if related_works has no non-empty related identifiers' do
          resource.related_identifiers.each do |rel_ident|
            rel_ident.related_identifier = ''
            rel_ident.save
          end
          expect(completions.has_related_works?).to be_falsey
        end
      end

      describe :optional_total do
        it "counts all of: #{OPTIONAL_FIELDS.join(', ')}" do
          expect(completions.optional_total).to eq(OPTIONAL_COUNT)
        end
      end

      describe :optional_completed do
        before(:each) do
          create(:description, resource: @resource)
          create(:description, resource: @resource, description_type: 'methods')
          create(:datacite_date, resource: @resource)
          @resource.subjects = [create(:subject)]
          create(:related_identifier, resource: @resource)
          ####
        end

        it "returns a full count for resources with all of: #{OPTIONAL_FIELDS.join(', ')}" do
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT)
        end

        it 'counts if date is missing' do
          resource.datacite_dates.each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end

        it 'counts if keywords are missing' do
          resource.subjects.clear
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end

        it 'counts if resource has no descriptions' do
          resource.descriptions.each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no methods' do
          resource.descriptions.where(description_type: 'methods').each(&:destroy)
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no non-nil methods' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = nil
            methods.save
          end
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
        it 'counts if resource has no non-blank methods' do
          resource.descriptions.where(description_type: 'methods').each do |methods|
            methods.description = ''
            methods.save
          end
          expect(completions.optional_completed).to eq(OPTIONAL_COUNT - 1)
        end
      end

      describe :all_warnings do

        before(:each) do
          expect(completions.required_completed).to eq(REQUIRED_COUNT) # just to be sure
          @resource.generic_files.each { |f| f.update(url: 'http://example.com') }
        end

        it 'warns on missing title' do
          resource.title = nil
          warnings = completions.all_warnings
          expect(warnings[0]).to include('title')
        end

        it 'warns on missing abstract' do
          @resource.descriptions.where(description_type: 'abstract').destroy_all
          warnings = completions.all_warnings
          expect(warnings[0]).to include('abstract')
        end

        it 'warns on missing author' do
          @resource.authors.destroy_all
          warnings = completions.all_warnings
          expect(warnings[0]).to include('author')
        end

        it 'warns on missing author email' do
          @resource.authors.each do |author|
            author.update(author_email: nil)
          end
          @completions = Completions.new(@resource)
          warnings = completions.all_warnings
          expect(warnings[0]).to include('email')
        end

        it 'warns on missing author affiliation' do
          @resource.authors.find_each do |author|
            author.affiliations.destroy_all
          end
          warnings = completions.all_warnings
          expect(warnings[0]).to include('affiliation')
        end

        it 'warns on unvalidated URLs' do
          @resource.data_files.newly_created.find_each do |upload|
            upload_file_name = upload.upload_file_name
            filename_encoded = ERB::Util.url_encode(upload_file_name)
            upload.url = "http://example.org/uploads/#{filename_encoded}"
            upload.status_code = '403'
            upload.save!
          end
          warnings = completions.all_warnings
          expect(warnings[0]).to include('valid')
        end
      end
    end
  end
end
