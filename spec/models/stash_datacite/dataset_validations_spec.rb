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
        @author3 = create(:author,
                          author_first_name: @user.first_name,
                          author_last_name: @user.last_name,
                          author_email: @user.email,
                          author_orcid: @user.orcid,
                          resource_id: @resource.id)
        @resource.subjects << [create(:subject), create(:subject), create(:subject)]
        create(:data_file, resource: @resource)
        @readme = create(:data_file, resource: @resource, upload_file_name: 'README.md')
        create(:data_file, resource: @resource)
        create(:data_file, resource: @resource)
        @resource.reload
      end

      describe :errors do
        it 'returns no errors if things are correctly filled' do
          validations = DatasetValidations.new(resource: @resource)
          allow(validations).to receive(:s3_error_uploads).and_return([]) # don't check with live S3 for this test
          expect(validations.errors).to be_empty
        end
      end

      describe :title do
        it 'returns error an error object if title not filled' do
          @resource.update(title: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.title
          expect(error.message).to include('dataset title')
          expect(error.ids.first).to eq("title__#{@resource.id}")
        end
      end

      describe :authors do
        it 'returns error for missing first or last name' do
          @author2.update(author_first_name: '')
          validations = DatasetValidations.new(resource: @resource)
          errors = validations.authors
          error = errors.first
          expect(errors.count).to eq(1)
          expect(error.message).to include('2nd')
          expect(error.message).to include('first and last name')
          expect(error.ids.first).to include('author_first_name__')
        end

        it 'returns error for missing affiliation' do
          @author2.affiliation.update(long_name: '*')
          validations = DatasetValidations.new(resource: @resource)
          errors = validations.authors
          error = errors.first
          expect(errors.count).to eq(1)
          expect(error.message).to include('2nd')
          expect(error.message).to include('institutional affiliation')
          expect(error.ids.first).to include('instit_affil__')
        end

        it 'returns error for missing corresponding author email' do
          @author3.update(author_email: '')
          validations = DatasetValidations.new(resource: @resource)
          errors = validations.authors
          error = errors.first
          expect(errors.count).to eq(1)
          expect(error.message).to include("submitting author's email")
          expect(error.ids.first).to include('author_email__')
        end
      end

      describe :research_domain do
        it 'returns error an error object if research domain (FOS subject) not filled' do
          @resource.update(subjects: [])
          validations = DatasetValidations.new(resource: @resource)
          error = validations.research_domain
          expect(error.message).to include('research domain')
          expect(error.ids.first).to eq("fos_subjects__#{@resource.id}")
        end
      end

      describe :abstract do
        it 'returns error for missing abstract' do
          abstract = @resource.descriptions.where(description_type: 'abstract').first
          abstract.update(description: '')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.abstract
          expect(error.message).to include('abstract')
          expect(error.ids.first).to eq('abstract_label')
        end
      end

      describe :article_id do
        it 'gives error for unfilled publication' do
          @resource.identifier.update(import_info: 'published')

          validations = DatasetValidations.new(resource: @resource)
          error = validations.article_id.first

          expect(error.message).to include('journal of the related publication')
          expect(error.ids).to eq(%w[publication])
        end

        it 'gives error for unfilled publication doi if publication' do
          @resource.identifier.update(import_info: 'published')
          StashEngine::InternalDatum.create(data_type: 'publicationName',
                                            value: 'Barrel of Monkeys: the Primate Journal',
                                            identifier_id: @resource.identifier_id)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.article_id.first

          expect(error.message).to include('formatted DOI')
          expect(error.ids).to eq(%w[primary_article_doi])
        end

        it 'gives error for unfilled manuscript number if manuscript' do
          @resource.identifier.update(import_info: 'manuscript')
          StashEngine::InternalDatum.create(data_type: 'publicationName',
                                            value: 'Barrel of Monkeys: the Primate Journal',
                                            identifier_id: @resource.identifier_id)

          validations = DatasetValidations.new(resource: @resource)
          error = validations.article_id.first

          expect(error.message).to include('manuscript number')
          expect(error.ids).to eq(%w[msId])
        end

        it 'gives a formatting error when someone puts in a URL instead of a DOI' do
          @resource.identifier.update(import_info: 'published')
          StashEngine::InternalDatum.create(data_type: 'publicationName',
                                            value: 'Barrel of Monkeys: the Primate Journal',
                                            identifier_id: @resource.identifier_id)
          create(:related_identifier, resource_id: @resource.id, related_identifier_type: 'url', work_type:
            'primary_article')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.article_id.first

          expect(error.message).to include('formatted DOI')
          expect(error.ids).to eq(%w[primary_article_doi])
        end

        it "doesn't give error if manuscript filled" do
          StashEngine::InternalDatum.create(data_type: 'publicationName',
                                            value: 'Barrel of Monkeys: the Primate Journal',
                                            identifier_id: @resource.identifier_id)

          StashEngine::InternalDatum.create(data_type: 'manuscriptNumber',
                                            value: '12xu',
                                            identifier_id: @resource.identifier_id)
          validations = DatasetValidations.new(resource: @resource)
          errors = validations.article_id

          expect(errors).to eq([])
        end

        it "doesn't give error if DOI filled" do
          StashEngine::InternalDatum.create(data_type: 'publicationName',
                                            value: 'Barrel of Monkeys: the Primate Journal',
                                            identifier_id: @resource.identifier_id)
          create(:related_identifier, work_type: 'primary_article', resource_id: @resource.id,
                                      related_identifier: 'https://doi.org/12346/4387', related_identifier_type: 'doi')

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.article_id

          expect(errors).to eq([])
        end
      end

      describe :s3_error_uploads do
        it 'returns missing files when files uploaded to s3 are not present' do
          files = @resource.generic_files
          files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end

          validations = DatasetValidations.new(resource: @resource)
          error = validations.s3_error_uploads
          expect(error.message).to include('Check that the following file(s) have uploaded')
          expect(error.message).to include(files[0].upload_file_name)
          expect(error.message).to include(files[1].upload_file_name)
          expect(error.message).to include(files[2].upload_file_name)
          expect(error.ids.first).to eq('filelist_id')
        end

        it 'does not check missing files once Merritt processing is complete' do
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end
          allow(@resource).to receive('submitted?').and_return(true)

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.s3_error_uploads
          expect(errors).to eq([])
        end

        it 'only checks files that are new uploads and are not urls' do
          @resource.generic_files.first.update(file_state: 'copied')
          @resource.generic_files.second.update(file_state: 'copied')
          @resource.generic_files.third.update(url: 'http://example.com')
          @resource.generic_files.fourth.update(file_state: 'copied')
          @resource.generic_files.map(&:calc_s3_path).each do |s3_path|
            allow(Stash::Aws::S3).to receive('exists?').with(s3_key: s3_path).and_return(false)
          end

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.s3_error_uploads
          expect(errors).to eq([])
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

          expect(errors).to eq([])
        end

        it 'returns no errors when all newly created files are valid' do
          @resource.data_files.newly_created.find_each do |upload|
            upload.status_code = 200
            upload.save!
          end

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.url_error_validating

          expect(errors).to eq([])
        end

        it 'returns error when at least one newly created file has an error' do
          upload = @resource.data_files.take
          upload.status_code = 403
          upload.save!

          validations = DatasetValidations.new(resource: @resource)
          error = validations.url_error_validating

          expect(error.message).to include('are available and publicly viewable')
          expect(error.message).to include(@resource.data_files.first.upload_file_name)
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

          expect(error.message).to include('are available and publicly viewable')
          expect(error.message).to include(@resource.software_files.first.upload_file_name)
        end

      end

      describe :required_data_files do
        before(:each) do
          @resource.generic_files.each { |f| f.update(url: 'http://example.com') }
        end

        it 'requires at least one data file' do
          @resource.data_files.destroy_all
          validations = DatasetValidations.new(resource: @resource)
          error = validations.data_required
          expect(error[0].message).to include('one data file')
        end

        it 'requires a README file, in addition to at least one data file' do
          @readme.update(upload_file_name: 'some-bogus-filename.txt')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.data_required
          expect(error[0].message).to include('README')

          @readme.update(upload_file_name: 'README.md')
          error = validations.data_required
          expect(error).to be_empty
        end

        it 'does not care about the file extension of a README' do
          @readme.update(upload_file_name: 'README.bogus-extension')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.data_required
          expect(error).to be_empty
        end

        it 'warns about incorrectly capitalized README' do
          @readme.update(upload_file_name: 'ReadMe.txt')
          validations = DatasetValidations.new(resource: @resource)
          error = validations.data_required
          expect(error[0].message).to include('capitalize')
        end
      end

      describe :over_file_count do
        it 'gives error if over file count' do
          allow(APP_CONFIG.maximums).to receive(:files).and_return(2) # limit is lower than our files

          validations = DatasetValidations.new(resource: @resource)
          error = validations.over_file_count

          expect(error.message).to include('limit the number of files to 2')
          expect(error.ids.first).to eq('filelist_id')
        end
      end

      describe :over_files_size do
        it 'gives an error if over file size for merritt data files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::DataFile')

          allow(APP_CONFIG.maximums).to receive(:merritt_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.over_files_size

          expect(errors.first.message).to include('Data uploads are limited')
          expect(errors.first.ids.first).to eq('filelist_id')
        end

        it 'gives an error if over file size for zenodo software files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::SoftwareFile')
          @resource.reload

          allow(APP_CONFIG.maximums).to receive(:zenodo_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.over_files_size

          expect(errors.first.message).to include('Software uploads are limited')
          expect(errors.first.ids.first).to eq('filelist_id')
        end

        it 'gives an error if over file size for zenodo supplemental files' do
          size = @resource.generic_files.sum(:upload_file_size)
          @resource.generic_files.update_all(type: 'StashEngine::SuppFile')
          @resource.reload

          allow(APP_CONFIG.maximums).to receive(:zenodo_size).and_return(size - 1)

          validations = DatasetValidations.new(resource: @resource)
          errors = validations.over_files_size

          expect(errors.first.message).to include('Supplemental uploads are limited')
          expect(errors.first.ids.first).to eq('filelist_id')
        end
      end
    end
  end
end
