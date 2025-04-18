# == Schema Information
#
# Table name: stash_engine_curation_stats
#
#  id                          :bigint           not null, primary key
#  author_revised              :integer
#  author_versioned            :integer
#  datasets_curated            :integer
#  datasets_to_aar             :integer
#  datasets_to_be_curated      :integer
#  datasets_to_embargoed       :integer
#  datasets_to_published       :integer
#  datasets_to_withdrawn       :integer
#  datasets_unclaimed          :integer
#  date                        :datetime
#  new_datasets                :integer
#  new_datasets_to_peer_review :integer
#  new_datasets_to_submitted   :integer
#  ppr_to_curation             :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_stash_engine_curation_stats_on_date  (date) UNIQUE
#
module StashEngine
  describe CurationStats do

    include Mocks::Aws
    include Mocks::CurationActivity
    include Mocks::Datacite
    include Mocks::RSolr
    include Mocks::Salesforce
    include Mocks::Stripe

    before(:each) do
      mock_aws!
      mock_solr!
      mock_datacite!
      mock_salesforce!
      mock_stripe!
      neuter_curation_callbacks!
      Timecop.travel(Time.now.utc - 1.minute)
      @curator = create(:user, role: 'curator')
      @user = create(:user, tenant_id: 'dryad')
      @system_user = create(:user, id: 0, first_name: 'Dryad', last_name: 'System')

      # setup some identifiers, each with one resource
      @res = []
      @idents = [
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/123'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/456'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/789'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/abc'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/def'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/ghi')
      ]
      @idents.each do |i|
        @res << create(:resource, identifier_id: i.id, user: @user, tenant_id: 'dryad')
      end

      @day = Time.now.utc.to_date
      @day1 = @day + 1.day
      @day2 = @day + 2.days
      Timecop.return
    end

    describe :status_on_date do
      it 'does not assign a status when created after the date' do
        stats = CurationStats.create(date: @day - 1.day)
        expect(stats.status_on_date(@idents.first)).to be(nil)
      end

      it 'assigns in_progress when first created' do
        stats = CurationStats.create(date: @day)
        expect(stats.status_on_date(@idents.first)).to eq('in_progress')
      end

      it 'keeps the last status' do
        i = @idents.first
        i.resources.first.curation_activities.first.update(status: 'peer_review')
        stats = CurationStats.create(date: @day1)
        expect(stats.status_on_date(@idents.first)).to eq('peer_review')
      end

      it 'finds an intermediate status' do
        @res.first.curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day1 + 1.second)
        @res.first.curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day2 + 1.second)
        stats = CurationStats.create(date: @day + 1.day)
        expect(stats.status_on_date(@idents.first)).to eq('curation')
      end
    end

    describe 'with deleted records' do
      it 'does not fail if the resource was deleted' do
        @res[0].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        res_new.delete
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
      end

      it 'does not fail if the resource was deleted' do
        @res[0].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        res_new.identifier.delete
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
      end
    end

    describe :datasets_curated do
      it 'knows when there are none' do
        # @res[0] stays in_progress
        # NO -- move into curation, but not out
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into published, but on day1
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day1 + 1.second)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day1 + 2.seconds)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_curated).to eq(0)
      end

      it 'counts correctly when there are some' do
        # NO -- move into curation, but not out
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # YES -- move into published
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        # YES -- move into embargoed
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_curated).to eq(2)
      end
    end

    describe :datasets_to_be_curated do
      it 'knows when there are none' do
        # NO -- move into peer_review
        @res[2].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_to_be_curated).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- user submitted
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(1)

        # YES -- journal notification out of PPR
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(2)

        # YES -- System did several CA's, but the actual last edit was the user
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @system_user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @system_user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(3)

        # YES -- curator took the dataset out of peer_review
        @res[3].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        res_new = create(:resource, identifier_id: @res[3].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'in_progress', user: @curator, created_at: @day)
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(4)

        # YES -- curator is working on it, but user submitted in the past
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day - 2.days)
        res_new2 = create(:resource, identifier_id: @res[4].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new2.curation_activities << CurationActivity.create(status: 'in_progress', user: @curator, created_at: @day)
        res_new2.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(5)
      end
    end

    describe :datasets_unclaimed do
      it 'knows when there are none' do
        stats = CurationStats.create(date: @day)

        # NO -- move into peer_review
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- move into curation
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- user submitted and added a curator
        @res[3].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[3].curation_activities << CurationActivity.create(note: 'Changing curator to Any Name', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- system auto-assigns a curator
        @res[4].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        @res[4].curation_activities << CurationActivity.create(note: 'System auto-assigned curator Any Name.', user: @curator, created_at: @day)
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- user submitted
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(1)

        # YES -- journal notification out of PPR
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(2)

        # YES -- System did several CA's, but the actual last edit was the user
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @system_user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'in_progress', user: @system_user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(3)

        # YES -- curator took the dataset out of peer_review
        @res[3].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        res_new = create(:resource, identifier_id: @res[3].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'in_progress', user: @curator, created_at: @day)
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(4)

        # YES -- user submitted, a curator was assigned, then the curator was unassigned
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', note: 'Changing curator to Any Name.', user: @curator,
                                                               created_at: @day)
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', note: 'Changing curator to unassigned.', user: @curator,
                                                               created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(5)
      end
    end

    describe :new_datasets_to_submitted do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into peer_review
        @res[2].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.new_datasets_to_submitted).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day1)

        # NO -- move into curation, but not actually submitted
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(0)

        # YES -- move into submitted
        @res[1].resource_states.first.update(resource_state: 'submitted')
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(1)

        # YES -- move into published
        @res[2].resource_states.first.update(resource_state: 'submitted')
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day1)
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day1)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # NO -- was submitted previously
        @res[3].resource_states.first.update(resource_state: 'submitted')
        @res[3].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # YES -- but there are two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident')
        res_new = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day1)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new2.resource_states.first.update(resource_state: 'submitted')
        res_new2.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)

        # NO -- there are two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new3.resource_states.first.update(resource_state: 'submitted')
        res_new3.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day1 - 2.days)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new4.resource_states.first.update(resource_state: 'submitted')
        res_new4.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)
        Timecop.return
      end
    end

    describe :new_datasets_to_peer_review do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into submitted
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.new_datasets_to_peer_review).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # NO -- move into curation, but not actually submitted
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(0)

        # YES -- move into peer_review
        @res[1].resource_states.first.update(resource_state: 'submitted')
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(1)

        # YES -- move into published
        @res[2].resource_states.first.update(resource_state: 'submitted')
        @res[2].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # NO -- was submitted previously
        @res[3].resource_states.first.update(resource_state: 'submitted')
        @res[3].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # YES -- but this dataset has two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        res_new.curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new2.resource_states.first.update(resource_state: 'submitted')
        res_new2.curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # NO -- this dataset has two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new3.resource_states.first.update(resource_state: 'submitted')
        res_new3.curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day - 2.days)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new4.resource_states.first.update(resource_state: 'submitted')
        res_new4.curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # YES -- goes through 'submitted' before 'peer_review
        @res[4].resource_states.first.update(resource_state: 'submitted')
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        @res[4].curation_activities << CurationActivity.create(status: 'peer_review', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(4)
        Timecop.return
      end
    end

    describe :ppr_to_curation do
      it 'knows when there are none' do
        # NO -- move to submitted after a curation status
        @res[0].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new2.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
        Timecop.return
      end

      it 'counts correctly when there are some' do
        # YES -- move to submitted after a PPR status
        @res[0].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(1)
      end
    end

    # Test the fields of format `datasets_to_XXXXX`
    # Focus on the `aar` field, with occasional test of the others, since they use
    # essentially the same calculation.
    describe :datasets_to_some_status do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into submitted
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_to_aar).to eq(0)
        expect(stats.datasets_to_embargoed).to eq(0)
        expect(stats.datasets_to_published).to eq(0)
        expect(stats.datasets_to_withdrawn).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # NO -- curation to published
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(0)
        expect(stats.datasets_to_published).to eq(1)

        # NO -- peer_review to aar
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(0)

        # YES -- curation to aar
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(1)

        # YES -- curation to aar, but only count once when it happens twice to the same dataset
        @res[3].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[3].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        @res[3].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[3].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)

        # NO -- was curated previously
        @res[4].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day - 2.days)
        @res[4].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)

        # NO -- was published by system
        @res[5].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day - 2.days)
        @res[5].curation_activities << CurationActivity.create(status: 'embargoed', user: @curator, created_at: @day - 2.days)
        @res[5].curation_activities << CurationActivity.create(status: 'embargoed', user: @curator, created_at: @day - 1.day)
        @res[5].curation_activities << CurationActivity.create(status: 'published', user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)
        expect(stats.datasets_to_published).to eq(1)

        # YES, two withdrawn, from different statuses
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day - 1.day)
        @res[0].curation_activities << CurationActivity.create(status: 'withdrawn', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day - 1.day)
        @res[1].curation_activities << CurationActivity.create(status: 'withdrawn', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_withdrawn).to eq(2)
      end
    end

    describe :author_revised do
      it 'knows when there are none' do
        stats = CurationStats.create(date: @day)

        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        expect(stats.author_revised).to eq(0)

        # NO -- move into curation, but it was previously in AAR
        @res[1].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        expect(stats.author_revised).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version
        @res[0].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.author_revised).to eq(1)

        # YES -- with different versions
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @user, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        res_new.curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_revised).to eq(2)
      end
    end

    describe :author_versioned do
      it 'knows when there are none' do
        # NO -- just a normal submission
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)

        stats = CurationStats.create(date: @day)
        expect(stats.author_versioned).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version (unlikely)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(1)

        # YES -- with different versions submitted on the same day
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'embargoed', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @user, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(2)

        # YES -- with different versions submitted on different days
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day - 2.days)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day - 2.days)
        res_new = create(:resource, identifier_id: @res[2].identifier.id, user: @user, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @user, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(3)

      end
    end

  end
end
