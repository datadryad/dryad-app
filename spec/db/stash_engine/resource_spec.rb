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
  end
end
