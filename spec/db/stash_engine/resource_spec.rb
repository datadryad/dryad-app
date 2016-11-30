require 'db_spec_helper'

module StashEngine
  describe Resource do
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
  end
end
