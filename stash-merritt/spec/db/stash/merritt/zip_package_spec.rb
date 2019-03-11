require 'db_spec_helper'

module Stash
  module Merritt
    describe ZipPackage do
      attr_reader :rails_root
      attr_reader :user
      attr_reader :tenant
      attr_reader :datacite_xml
      attr_reader :stash_wrapper_xml
      attr_reader :resource
      attr_reader :target_url
      attr_reader :zipfile_path
      attr_reader :url_helpers

      before(:each) do
        @rails_root = Dir.mktmpdir('rails_root')
        FileUtils.mkdir_p("#{rails_root}/tmp")
        allow(Rails).to receive(:root).and_return(rails_root)

        @user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          tenant_id: 'dataone'
        )
        @tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                 account: 'stash',
                                                                 password: 'stash',
                                                                 id_scheme: 'doi')
        allow(tenant).to receive(:tenant_id).and_return('dataone')
        allow(tenant).to receive(:short_name).and_return('DataONE')
        allow(tenant).to receive(:full_url) { |path_to_landing| URI::HTTPS.build(host: 'stash.example.edu', path: path_to_landing).to_s }
        allow(tenant).to receive(:sword_params).and_return(collection_uri: 'http://sword.example.edu/stash-dev')
        allow(StashEngine::Tenant).to receive(:find).with('dataone').and_return(tenant)

        @stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = StashDatacite::ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date,
          tenant_id: 'dataone'
        ).build

        @url_helpers = double(Module) # yes, apparently URL helpers are an anonymous module
        allow(url_helpers).to(receive(:show_path)) { |identifier| "/stash/#{identifier}" }

        # TODO: move this to ResourceBuilder
        stash_wrapper.inventory.files.each do |stash_file|
          data_file = stash_file.pathname
          placeholder_file = "#{resource.upload_dir}/#{data_file}"
          parent = File.dirname(placeholder_file)
          FileUtils.mkdir_p(parent) unless File.directory?(parent)
          File.open(placeholder_file, 'w') do |f|
            f.puts("#{data_file}\t#{stash_file.size_bytes}\t#{stash_file.mime_type}\t(placeholder)")
          end
        end
      end

      after(:each) do
        FileUtils.remove_dir(rails_root)
      end

      def zipfile
        @zipfile ||= ::Zip::File.open(zipfile_path)
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
          resource.identifier = nil
          resource.save!
          expect { ZipPackage.new(resource: resource) }.to raise_error(ArgumentError)
        end

        it 'fails if the resource has URL "uploads"'

        it 'sets publication year if needed'
      end

      describe :zipfile do
        it 'builds a zipfile' do
          expected_metadata = Dir.glob('spec/data/archive/*').map do |path|
            [File.basename(path), File.read(path)]
          end.to_h

          package = ZipPackage.new(resource: resource)
          @zipfile_path = package.zipfile

          expected_metadata.each do |path, content|
            if path.end_with?('xml')
              actual = zip_entry(path).gsub(/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]Z/, '')
              expected = content.gsub(/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]Z/, '')
              expect(actual).to be_xml(expected, path)
            else
              actual = zip_entry(path).strip
              expected = content.strip
              if actual != expected
                now = Time.now.to_i
                FileUtils.mkdir('tmp') unless File.directory?('tmp')
                File.open("tmp/#{now}-expected-#{path}", 'w') { |f| f.write(expected) }
                File.open("tmp/#{now}-actual-#{path}", 'w') { |f| f.write(actual) }
              end
              expect(actual).to eq(expected)
            end
          end
        end

        it 'includes a delete list if needed' do
          deleted = []
          resource.file_uploads.each_with_index do |upload, index|
            next unless index.even?
            upload.file_state = 'deleted'
            upload.save
            deleted << upload.upload_file_name
          end

          package = ZipPackage.new(resource: resource)
          @zipfile_path = package.zipfile
          mrt_delete = zip_entry('mrt-delete.txt')
          deleted.each do |filename|
            expect(mrt_delete).to include(filename)
          end
        end

        describe 'mrt-embargo.txt' do
          it 'includes the embargo end date if present' do
            end_date = Time.new(2020, 1, 1, 0, 0, 1, '+12:45')
            resource.publication_date = end_date.to_s
            package = ZipPackage.new(resource: resource)
            @zipfile_path = package.zipfile
            mrt_embargo = zip_entry('mrt-embargo.txt')
            expect(mrt_embargo.strip).to eq('embargoEndDate:2019-12-31T11:15:01Z')
          end

          it 'sets end date to none if no end date present' do
            package = ZipPackage.new(resource: resource)
            @zipfile_path = package.zipfile
            mrt_embargo = zip_entry('mrt-embargo.txt')
            expect(mrt_embargo.strip).to eq('embargoEndDate:none')
          end
        end
      end

      describe :dc4_xml do
        it 'builds Datacite 4 XML' do
          package = ZipPackage.new(resource: resource)
          expect(package.dc4_xml).to be_xml(datacite_xml)
        end
      end

      describe :cleanup! do
        it 'removes the working directory' do
          package = ZipPackage.new(resource: resource)
          @zipfile_path = package.zipfile
          workdir = File.dirname(zipfile_path)
          package.cleanup!
          expect(File.exist?(workdir)).to eq(false)
        end

      end

      describe :to_s do
        attr_reader :package_str
        before(:each) do
          package = ZipPackage.new(resource: resource)
          @package_str = package.to_s
        end
        it 'includes the class name' do
          expect(package_str).to include(ZipPackage.name)
        end
        it 'includes the resource ID' do
          expect(package_str).to include(resource.id.to_s)
        end
      end
    end
  end
end
