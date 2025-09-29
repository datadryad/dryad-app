# == Schema Information
#
# Table name: stash_engine_curation_activities
#
#  id          :integer          not null, primary key
#  deleted_at  :datetime
#  keywords    :string(191)
#  note        :text(65535)
#  status      :string(191)      default("in_progress")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#  user_id     :integer
#
# Indexes
#
#  index_stash_engine_curation_activities_on_deleted_at          (deleted_at)
#  index_stash_engine_curation_activities_on_resource_id_and_id  (resource_id,id)
#
require 'ostruct'
require 'byebug'

module StashEngine
  RSpec.describe CurationActivity do
    let(:identifier) { create(:identifier) }
    let(:user) { create(:user) }
    let(:resource) { create(:resource, identifier: identifier) }
    let(:curation_activity) { create(:curation_activity, resource: resource) }

    context :basic_curation_activity do
      it 'shows the appropriate dataset identifier' do
        expect(curation_activity.resource.identifier.to_s).to eq(identifier.to_s)
      end

      it 'defaults status to :in_progress' do
        expect(curation_activity.status).to eql('in_progress')
      end

      it 'requires a resource' do
        activity = CurationActivity.new(resource: nil)
        expect(activity.valid?).to eql(false)
      end
    end

    context :latest do
      it 'returns the most recent activity' do
        ca = create(:curation_activity, resource: resource, status: 'peer_review', note: 'this is a test')
        expect(CurationActivity.latest(resource: resource)).to eql(ca)
      end
    end

    context :readable_status do
      it 'class method allows conversion of status to humanized status' do
        expect(CurationActivity.readable_status('submitted')).to eql('Submitted')
      end

      it 'returns a readable version of :peer_review' do
        curation_activity.peer_review!
        expect(curation_activity.readable_status).to eql('Private for peer review')
      end

      it 'returns a readable version of :action_required' do
        curation_activity.action_required!
        expect(curation_activity.readable_status).to eql('Action required')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each_key do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            curation_activity.send("#{s}!")
            expect(curation_activity.readable_status).to eql(s.humanize)
          end
        end
      end
    end

    context :curation_status_changed? do
      let(:curation_activity) { resource.curation_activities.first }
      it 'considers things changed if there is only one curation status for this resource' do
        expect(curation_activity.curation_status_changed?).to be true
      end

      it 'considers changed to be true if the last two curation statuses are unequal' do
        ca = create(:curation_activity, status: 'embargoed', resource: resource)
        expect(ca.curation_status_changed?).to be true
      end

      it 'considers changed to be false if the last two curation statuses are equal' do
        ca = create(:curation_activity, resource: resource, note: 'We need more about cats')
        expect(ca.curation_status_changed?).to be false
      end
    end

    context 'self.allowed_states(current_state)' do
      context 'when user is an admin' do
        let(:user) { create(:user, role: 'admin') }

        it 'indicates the states that are allowed from each' do
          expect(CurationActivity.allowed_states('in_progress', user)).to eq(%w[in_progress])

          expect(CurationActivity.allowed_states('curation', user)).to \
            eq(%w[processing peer_review curation action_required withdrawn embargoed published])

          expect(CurationActivity.allowed_states('withdrawn', user)).to \
            eq(%w[withdrawn curation])
        end
      end

      context 'when user is a data manager' do
        let(:user) { create(:user, role: 'manager') }

        CurationActivity::CURATOR_ALLOWED_STATES.each_key do |status|
          it "allows withdrawn for #{status} status" do
            expect(CurationActivity.allowed_states(status, user)).to include('withdrawn')
          end
        end
      end
    end

    it_should_behave_like 'soft delete record', :curation_activity
  end
end
