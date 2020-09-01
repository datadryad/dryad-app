module Stash
  module Merritt
    describe ZipPackage do

      before(:each) do
        @rails_root = Dir.mktmpdir('rails_root')
        FileUtils.mkdir_p("#{@rails_root}/tmp")
        allow(Rails).to receive(:root).and_return(@rails_root)

        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@example.edu',
                       tenant_id: 'dataone')
        @tenant = double(StashEngine::Tenant)
        allow(@tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                  account: 'stash',
                                                                  password: 'stash',
                                                                  id_scheme: 'doi')
        allow(@tenant).to receive(:tenant_id).and_return('dataone')
        allow(@tenant).to receive(:short_name).and_return('DataONE')
        allow(@tenant).to receive(:full_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }
        allow(@tenant).to receive(:sword_params).and_return(collection_uri: 'http://sword.example.edu/stash-dev')
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(@tenant)

        @stash_wrapper_xml = File.read('spec/data/stash-merritt/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(@stash_wrapper_xml)

        @resource = create(:resource, user: @user)
        create(:right, resource: @resource)

        stash_wrapper.inventory.files.each do |stash_file|
          data_file = stash_file.pathname
          placeholder_file = "#{@resource.upload_dir}/#{data_file}"
          parent = File.dirname(placeholder_file)
          create(:file_upload,
                 upload_file_name: data_file,
                 upload_file_size: stash_file.size_bytes,
                 upload_content_type: stash_file.mime_type,
                 resource: @resource)
          FileUtils.mkdir_p(parent) unless File.directory?(parent)
          File.open(placeholder_file, 'w') do |f|
            f.puts("#{data_file}\t#{stash_file.size_bytes}\t#{stash_file.mime_type}\t(placeholder)")
          end
        end
      end

      after(:each) do
        FileUtils.remove_dir(@rails_root)
      end

      def zipfile
        @zipfile ||= ::Zip::File.open(@zipfile_path)
      end

      def zip_entry(path)
        @zip_entries ||= {}
        @zip_entries[path] ||= begin
          entry = zipfile.find_entry(path)
          entry_io = entry.get_input_stream
          entry_io.read
        end
      end

      describe :initialize do
        it 'fails if the resource doesn\'t have an identifier' do
          @resource.identifier = nil
          expect { @resource.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      describe :zipfile do
        it 'builds a zipfile' do
          expected_metadata = Dir.glob('spec/data/stash-merritt/*').map do |path|
            [File.basename(path), File.read(path)]
          end.to_h

          package = ZipPackage.new(resource: @resource)
          @zipfile_path = package.zipfile

          # Ensure that each file is present in the zip, but don't compare the
          # contents in detail (may want to expand this)
          expected_metadata.each do |path, _content|
            expect(zip_entry(path).size).to be > 0
          end
        end

        it 'includes a delete list if needed' do
          deleted = []
          @resource.file_uploads.each_with_index do |upload, index|
            next unless index.even?

            upload.file_state = 'deleted'
            upload.save
            deleted << upload.upload_file_name
          end

          package = ZipPackage.new(resource: @resource)
          @zipfile_path = package.zipfile
          mrt_delete = zip_entry('mrt-delete.txt')
          deleted.each do |filename|
            expect(mrt_delete).to include(filename)
          end
        end
      end

      describe :dc4_xml do
        it 'builds Datacite 4 XML' do
          # Should look like spec/data/stash-merritt/mrt-datacite.xml
          package = ZipPackage.new(resource: @resource)

          actual = Hash.from_xml(package.dc4_xml)
          actual_res = actual['resource']
          expect(actual_res['titles']['title']).to eq(@resource.title)
          expect(actual_res['identifier']).to eq(@resource.identifier.identifier)
          expect(actual_res['publicationYear']).to eq(@resource.publication_date.year.to_s)
        end
      end

      describe :to_s do
        attr_reader :package_str
        before(:each) do
          package = ZipPackage.new(resource: @resource)
          @package_str = package.to_s
        end
        it 'includes the class name' do
          expect(package_str).to include(ZipPackage.name)
        end
        it 'includes the resource ID' do
          expect(package_str).to include(@resource.id.to_s)
        end
      end
    end
  end
end
