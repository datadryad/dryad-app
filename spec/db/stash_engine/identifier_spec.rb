require 'db_spec_helper'

module StashEngine
  describe Identifier do
    attr_reader :identifier
    attr_reader :resource
    attr_reader :download_count
    attr_reader :view_count

    before(:each) do
      @identifier = Identifier.create(identifier_type: 'DOI', identifier: '10.123/456')
      @resource = Resource.create(identifier_id: identifier.id)

      @download_count = 7
      @view_count = 17
      ResourceUsage.create(
          resource_id: resource.id,
          downloads: download_count,
          views: view_count
      )
    end
    
    describe '@download_count' do
      it 'returns the download count' do
        expect(identifier.download_count).to be(download_count)
      end
    end

    describe '@view_count' do
      it 'returns the view count' do
        expect(identifier.view_count).to be(view_count)
      end
    end
  end
end
