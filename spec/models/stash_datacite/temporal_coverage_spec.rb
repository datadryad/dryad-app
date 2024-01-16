# == Schema Information
#
# Table name: stash_datacite_temporal_coverages
#
#  id          :integer          not null, primary key
#  description :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
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
