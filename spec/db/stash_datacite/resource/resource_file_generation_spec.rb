require 'spec_helper'

require 'tmpdir'

module StashDatacite
  module Resource
    describe ResourceFileGeneration do
      attr_reader :rails_root
      attr_reader :user
      attr_reader :tenant
      attr_reader :datacite_xml
      attr_reader :stash_wrapper_xml
      attr_reader :resource
      attr_reader :target_url
      attr_reader :zipfile_path

      before(:each) do
        @rails_root = Dir.mktmpdir('rails_root')
        FileUtils.mkdir_p("#{rails_root}/tmp")
        allow(Rails).to receive(:root).and_return(rails_root)

        @user = StashEngine::User.create(
          uid: 'lmuckenhaupt-example@example.edu',
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@example.edu',
          provider: 'developer',
          tenant_id: 'dataone'
        )
        @tenant = double(StashEngine::Tenant)
        allow(tenant).to receive(:identifier_service).and_return(shoulder: 'doi:10.15146/R3',
                                                                 account: 'stash',
                                                                 password: 'stash',
                                                                 id_scheme: 'doi')
        allow(tenant).to receive(:short_name).and_return('DataONE')

        @stash_wrapper_xml = File.read('spec/data/archive/stash-wrapper.xml')
        stash_wrapper = Stash::Wrapper::StashWrapper.parse_xml(stash_wrapper_xml)

        @datacite_xml = File.read('spec/data/archive/mrt-datacite.xml')
        dcs_resource = Datacite::Mapping::Resource.parse_xml(datacite_xml)

        @resource = ResourceBuilder.new(
          user_id: user.id,
          dcs_resource: dcs_resource,
          stash_files: stash_wrapper.inventory.files,
          upload_date: stash_wrapper.version_date
        ).build

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

        # TODO: stop allowing this
        @target_url = 'https://stash-dev.example.edu/doi:10.15146/R3RG6G'
        ezid_client = instance_double(StashEzid::Client)
        allow(ezid_client).to receive(:update_metadata)
        allow(StashEzid::Client).to receive(:new).and_return(ezid_client)
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

      describe '#generate_merritt_zip' do
        it 'builds a zipfile' do
          expected_metadata = Dir.glob('spec/data/archive/*').map do |path|
            [File.basename(path), File.read(path)]
          end.to_h

          rfg = Resource::ResourceFileGeneration.new(resource, tenant)
          folder = StashEngine::Resource.uploads_dir
          @zipfile_path = rfg.generate_merritt_zip(folder, target_url)

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

        it 'includes a delete list' do
          deleted = []
          resource.file_uploads.each_with_index do |upload, index|
            next unless index.even?
            upload.file_state = 'deleted'
            upload.save
            deleted << upload.upload_file_name
          end

          rfg = Resource::ResourceFileGeneration.new(resource, tenant)
          folder = StashEngine::Resource.uploads_dir
          @zipfile_path = rfg.generate_merritt_zip(folder, target_url)
          mrt_delete = zip_entry('mrt-delete.txt')
          deleted.each do |filename|
            expect(mrt_delete).to include(filename)
          end
        end
      end
    end
  end
end
