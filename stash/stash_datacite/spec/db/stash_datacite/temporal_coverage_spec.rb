require 'db_spec_helper'

module StashDatacite
  describe TemporalCoverage do
    attr_reader :resource

    before(:each) do
      user = StashEngine::User.create(
        email: 'lmuckenhaupt@example.edu',
        tenant_id: 'dataone'
      )
      @resource = StashEngine::Resource.create(user_id: user.id)
    end

    describe '#temporal_coverage' do
      it 'sets a temporal coverage' do
        temporal_coverage = TemporalCoverage.new(resource_id: @resource.id)
        temporal_coverage.description = 'Paleozoic'
        temporal_coverage.save

        expect(resource.temporal_coverages.first.description).to eq('Paleozoic')
      end
    end
  end
end
