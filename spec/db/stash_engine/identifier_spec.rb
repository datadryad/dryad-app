require 'db_spec_helper'

module StashEngine
  describe Identifier do
    attr_reader :identifier
    attr_reader :usage1
    attr_reader :usage2
    attr_reader :res1
    attr_reader :res2

    before(:each) do
      @identifier = Identifier.create(identifier_type: 'DOI', identifier: '10.123/456')
      @res1 = Resource.create(identifier_id: identifier.id)
      @res2 = Resource.create(identifier_id: identifier.id)

      @usage1 = ResourceUsage.create(resource_id: res1.id, downloads: 3, views: 7)
      @usage2 = ResourceUsage.create(resource_id: res2.id, downloads: 8, views: 6)
    end

    describe '@download_count' do
      it 'returns the download count' do
        download_count = usage1.downloads + usage2.downloads
        expect(identifier.download_count).to be(download_count)
      end
    end

    describe '@view_count' do
      it 'returns the view count' do
        view_count = usage1.views + usage2.views
        expect(identifier.view_count).to be(view_count)
      end
    end

    describe 'versioning' do
      before(:each) do
        ResourceState.create(resource_id: res1.id, resource_state: :published)
        Version.create(resource_id: res1.id, version: 1)

        ResourceState.create(resource_id: res2.id, resource_state: :in_progress)
        Version.create(resource_id: res2.id, version: 2)
      end

      describe '#last_submitted_version' do
        it 'returns the last submitted version' do
          lsv = identifier.last_submitted_version
          expect(lsv.id).to eq(res1.id)
        end

        it 'sorts by version, descending'
      end

      describe '#in_progress_version' do
        it 'returns the in-progress version' do
          ipv = identifier.in_progress_version
          expect(ipv.id).to eq(res2.id)
        end
      end

      describe '#in_progress?' do
        it 'returns true if an in-progress version exists' do
          expect(identifier.in_progress?).to eq(true)
        end
        it 'returns false if no in-progress version exists'
      end
    end
  end
end
