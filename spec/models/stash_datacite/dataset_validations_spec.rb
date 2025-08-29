module StashDatacite
  module Resource
    describe DatasetValidations do

      before(:each) do
        @user = create(:user)
        @resource = create(:resource, user: @user)
        @resource.save
        create(:resource_type, resource: @resource)
        @author1 = @resource.authors.first
        @author2 = create(:author, resource: @resource)
        @author3 = create(:author, resource: @resource)
        @resource.subjects << [create(:subject), create(:subject), create(:subject)]
        create(:description, resource: @resource, description_type: 'technicalinfo')
        4.times { create(:data_file, resource: @resource) }
        @resource.reload
      end

      describe :errors do
        it 'returns no errors if things are correctly filled' do
          validations = DatasetValidations.new(resource: @resource)
          allow(validations).to receive(:s3_error_uploads).and_return([]) # don't check with live S3 for this test
          expect(validations.errors).to be_falsey
        end
      end

      describe :title do
        it 'returns error if title not filled' do
          @resource.update(title: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.title
          expect(error).to eq('Blank title')
        end
        it 'returns error for nondescript title' do
          @resource.update(title: 'Figure S1 Data supplement')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.title
          expect(error).to eq('Nondescriptive title')
        end
        it 'returns error for ALL CAPS title' do
          @resource.update(title: @resource.title.upcase)
          validations = DatasetValidations.new(resource: @resource)
          error = validations.title
          expect(error).to eq('All caps title')
        end
      end

      describe :authors do
        it 'returns error for missing submitter' do
          @author1.update(author_orcid: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Submitter missing')
        end
        it 'returns error for missing submitter email' do
          @author1.update(author_email: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Submitter email missing')
        end
        it 'returns error for missing firstname' do
          @author2.update(author_first_name: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Names missing')
        end
        it 'returns error for missing affiliation' do
          @author2.affiliation.destroy
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Affiliations missing')
        end
        it 'returns error for duplicate name' do
          @author2.update(author_first_name: @author1.author_first_name, author_last_name: @author1.author_last_name)
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Duplicate author names')
        end
        it 'returns error for duplicate email' do
          @author2.update(author_email: @author1.author_email)
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Duplicate author emails')
        end
        it 'returns error for no corresp' do
          @resource.authors.update_all(corresp: false)
          validations = DatasetValidations.new(resource: @resource)
          error = validations.authors
          expect(error).to eq('Published email missing')
        end
      end

      describe :abstract do
        it 'returns error for missing abstract' do
          abstract = @resource.descriptions.where(description_type: 'abstract').first
          abstract.update(description: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.abstract
          expect(error).to eq('Abstract missing')
        end
      end

      describe :subjects do
        it 'returns error an error object if research domain (FOS subject) not filled' do
          @resource.update(subjects: [])
          validations = DatasetValidations.new(resource: @resource)
          error = validations.subjects
          expect(error).to eq('Research domain missing')
        end
      end

      describe :collection_errors do
        before(:example) do
          @collection = create(:resource, user: @user)
          @collection.save
          create(:resource_type_collection, resource: @collection)
          @author1 = @collection.authors.first
          @author2 = create(:author, resource: @collection)
          @author3 = create(:author, resource: @collection)
          @collection.subjects << [create(:subject), create(:subject), create(:subject)]
          @collection.reload
        end

        it 'returns collected datasets error when collection has no related identifiers' do
          validations = DatasetValidations.new(resource: @collection)
          error = validations.collected_datasets
          expect(error).to eq('No datasets in the collection')
        end

        it 'returns no errors when collected datasets are present' do
          create(:related_identifier, relation_type: 'haspart', work_type: 'dataset', resource_id: @collection.id,
                                      related_identifier: 'https://doi.org/12346/4387', related_identifier_type: 'doi')
          validations = DatasetValidations.new(resource: @collection)
          error = validations.collected_datasets
          expect(error).to be_falsey
        end
      end

      describe :required_data_files do
        before(:each) do
          @resource.generic_files.each { |f| f.update(url: 'http://example.com') }
        end

        it 'requires at least one data file' do
          @resource.data_files.destroy_all
          create(:data_file, resource: @resource, download_filename: 'README.md')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.data_required
          expect(error).to eq('No data files')
        end
      end

      describe :s3_error_uploads do
        it 'returns missing files when files uploaded to s3 are not present' do
          files = @resource.generic_files
          files.map(&:s3_staged_path).each do |s3_path|
            allow_any_instance_of(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end

          validations = DatasetValidations.new(resource: @resource)
          error = validations.s3_error_uploads
          expect(error).to eq('Upload file errors')
        end

        it 'does not check missing files once Merritt processing is complete' do
          @resource.generic_files.map(&:s3_staged_path).each do |s3_path|
            allow_any_instance_of(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end
          allow(@resource).to receive('submitted?').and_return(true)

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.s3_error_uploads
          expect(errors).to be_falsey
        end

        it 'only checks files that are new uploads and are not urls' do
          @resource.generic_files.first.update(file_state: 'copied')
          @resource.generic_files.second.update(file_state: 'copied')
          @resource.generic_files.third.update(url: 'http://example.com')
          @resource.generic_files.fourth.update(file_state: 'copied')
          @resource.generic_files.map(&:s3_staged_path).each do |s3_path|
            allow_any_instance_of(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.s3_error_uploads
          expect(errors).to be_falsey
        end
      end

      describe :url_error_validating do
        before(:each) do
          @resource.data_files.find_each do |upload|
            upload.url = "http://example.org/#{upload.upload_file_name}"
            upload.save!
          end
        end

        it 'returns no errors when no files are newly created' do
          new_files = @resource.data_files.newly_created
          new_files.find_each do |upload|
            upload.file_state = :copied
            upload.save!
          end

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.url_error_validating
          expect(errors).to be_falsey
        end

        it 'returns no errors when all newly created files are valid' do
          @resource.data_files.newly_created.find_each do |upload|
            upload.status_code = 200
            upload.save!
          end

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.url_error_validating
          expect(errors).to be_falsey
        end

        it 'returns error when at least one newly created file has an error' do
          upload = @resource.data_files.take
          upload.status_code = 403
          upload.save!

          validations = DatasetValidations.new(resource: @resource)
          error = validations.url_error_validating
          expect(error).to eq('URL file errors')
        end

        it 'returns error when at least one Zenodo file has an error' do
          # good uploads for dataset

          @resource.data_files.newly_created.find_each do |upload|
            upload.status_code = 200
            upload.save!
          end

          # bad upload for zenodo
          @resource.software_files << create(:software_file, status_code: 411, url: 'https://happy.clown.example.com')

          validations = DatasetValidations.new(resource: @resource)
          error = validations.url_error_validating
          expect(error).to eq('URL file errors')
        end
      end

      describe :over_max do
        it 'gives error if over file count' do
          allow(APP_CONFIG.maximums).to receive(:files).and_return(2) # limit is lower than our files

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_max
          expect(error).to eq('Too many data files (more than 100)')
        end

        it 'gives an error if over file size for data files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::DataFile')

          allow_any_instance_of(StashEngine::Identifier).to receive(:new_upload_size_limit).and_return(true)
          allow(APP_CONFIG.maximums).to receive(:upload_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_max
          expect(error).to eq('Over dataset file size limit')
        end

        it 'gives an error if over file size for merritt data files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.identifier.update(old_payment_system: true)
          @resource.generic_files.update_all(type: 'StashEngine::DataFile')

          allow(APP_CONFIG.maximums).to receive(:merritt_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_max
          expect(error).to eq('Over file size limit')
        end

        it 'gives an error if over file size for zenodo software files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::SoftwareFile')
          @resource.reload

          allow(APP_CONFIG.maximums).to receive(:zenodo_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_max
          expect(error).to eq('Over zenodo file size limit')
        end

        it 'gives an error if over file size for zenodo supplemental files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::SuppFile')
          @resource.reload

          allow(APP_CONFIG.maximums).to receive(:zenodo_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_max
          expect(error).to eq('Over zenodo file size limit')
        end
      end

      describe :required_readme do
        it 'requires a README' do
          @resource.descriptions.type_technical_info.first.destroy
          validations = DatasetValidations.new(resource: @resource)
          error = validations.readme_required
          expect(error).to eq('README file missing')
        end
      end
    end
  end
end
