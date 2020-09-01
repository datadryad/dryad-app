require 'rails_helper'

module StashDatacite
  describe TemporalCoverage do

    before(:each) do
      user = create(:user,
                    email: 'lmuckenhaupt@example.edu',
                    tenant_id: 'dataone')
      @resource = create(:resource, user_id: user.id)
    end

    describe '#temporal_coverage' do
      it 'sets a temporal coverage' do
        temporal_coverage = TemporalCoverage.new(resource_id: @resource.id)
        temporal_coverage.description = 'Paleozoic'
        temporal_coverage.save

        expect(@resource.temporal_coverages.first.description).to eq('Paleozoic')
      end
    end
  end
end
