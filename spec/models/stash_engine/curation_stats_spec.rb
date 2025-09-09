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
        create(:curation_activity, :curation, resource: @res.first, user: @curator, created_at: @day1 + 1.second)
        create(:curation_activity, :published, resource: @res.first, user: @curator, created_at: @day2 + 1.second)
        stats = CurationStats.create(date: @day + 1.day)
        expect(stats.status_on_date(@idents.first)).to eq('curation')
      end
    end

    describe 'with deleted records' do
      it 'does not fail if the resource was deleted' do
        CurationService.new(status: 'peer_review', resource: @res[0], user: @curator, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
        res_new.delete
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
      end

      it 'does not fail if the resource was deleted' do
        CurationService.new(status: 'peer_review', resource: @res[0], user: @curator, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
        res_new.identifier.delete
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
      end
    end

    describe :datasets_curated do
      it 'knows when there are none' do
        # @res[0] stays in_progress
        # NO -- move into curation, but not out
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        # NO -- move into published, but on day1
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day1 + 1.second)
        create(:curation_activity, resource: @res[2], user: @curator, created_at: @day1 + 2.seconds)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_curated).to eq(0)
      end

      it 'counts correctly when there are some' do
        # NO -- move into curation, but not out
        create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day)
        # YES -- move into published
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        create(:curation_activity, :published, resource: @res[1], user: @curator, created_at: @day)
        # YES -- move into embargoed
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day)
        create(:curation_activity, :published, resource: @res[2], user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_curated).to eq(2)
      end
    end

    describe :datasets_to_be_curated do
      it 'knows when there are none' do
        # NO -- move into peer_review
        CurationService.new(status: 'peer_review', resource: @res[2], user: @curator, created_at: @day).process
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_to_be_curated).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- user submitted
        CurationService.new(status: 'submitted', resource: @res[0], user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(1)

        # YES -- journal notification out of PPR
        CurationService.new(status: 'peer_review', resource: @res[1], user: @user, created_at: @day).process
        CurationService.new(status: 'submitted', resource: @res[1], user: @system_user, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(2)

        # YES -- System did several CA's, but the actual last edit was the user
        create(:curation_activity, :in_progress, resource: @res[2], user: @user, created_at: @day)
        create(:curation_activity, :in_progress, resource: @res[2], user: @system_user, created_at: @day)
        create(:curation_activity, :in_progress, resource: @res[2], user: @system_user, created_at: @day)
        CurationService.new(status: 'submitted', resource: @res[2], user: @system_user, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(3)

        # YES -- curator took the dataset out of peer_review
        CurationService.new(status: 'peer_review', resource: @res[3], user: @user, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[3].identifier.id, user: @curator, tenant_id: 'dryad')
        create(:curation_activity, :in_progress, resource: res_new, user: @curator, created_at: @day)
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(4)

        # YES -- curator is working on it, but user submitted in the past
        CurationService.new(status: 'submitted', resource: @res[4], user: @user, created_at: @day - 2.days)
        res_new2 = create(:resource, identifier_id: @res[4].identifier.id, user: @curator, tenant_id: 'dryad')
        create(:curation_activity, :in_progress, resource: res_new2, user: @curator, created_at: @day)
        CurationService.new(status: 'submitted', resource: res_new2, user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_to_be_curated).to eq(5)
      end
    end

    describe :datasets_unclaimed do
      it 'knows when there are none' do
        stats = CurationStats.create(date: @day)

        # NO -- move into peer_review
        CurationService.new(status: 'peer_review', resource: @res[1], user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- move into curation
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- user submitted and added a curator
        CurationService.new(status: 'submitted', resource: @res[3], user: @curator, created_at: @day).process
        create(:curation_activity, :curation, resource: @res[3], note: 'Changing curator to Any Name', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)

        # NO -- system auto-assigns a curator
        create(:curation_activity, :curation, :curation, resource: @res[4], user: @curator, created_at: @day)
        create(:curation_activity, :curation, resource: @res[4], note: 'System auto-assigned curator Any Name.', user: @curator, created_at: @day)
        create(:curation_activity, :curation, resource: @res[4], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- user submitted
        CurationService.new(status: 'submitted', resource: @res[0], user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(1)

        # YES -- journal notification out of PPR
        CurationService.new(status: 'peer_review', resource: @res[1], user: @user, created_at: @day).process
        CurationService.new(status: 'submitted', resource: @res[1], user: @system_user, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(2)

        # YES -- System did several CA's, but the actual last edit was the user
        create(:curation_activity, :in_progress, resource: @res[2], user: @user, created_at: @day)
        create(:curation_activity, :in_progress, resource: @res[2], user: @system_user, created_at: @day)
        create(:curation_activity, :in_progress, resource: @res[2], user: @system_user, created_at: @day)
        CurationService.new(status: 'submitted', resource: @res[2], user: @system_user, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(3)

        # YES -- curator took the dataset out of peer_review
        CurationService.new(status: 'peer_review', resource: @res[3], user: @user, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[3].identifier.id, user: @curator, tenant_id: 'dryad')
        create(:curation_activity, :in_progress, resource: res_new, user: @curator, created_at: @day)
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(4)

        # YES -- user submitted, a curator was assigned, then the curator was unassigned
        CurationService.new(status: 'submitted', resource: @res[4], user: @curator, created_at: @day).process
        CurationService.new(status: 'submitted', resource: @res[4], note: 'Changing curator to Any Name.', user: @curator, created_at: @day).process
        CurationService.new(status: 'submitted', resource: @res[4], note: 'Changing curator to unassigned.', user: @curator, created_at: @day).process
        stats.recalculate
        expect(stats.datasets_unclaimed).to eq(5)
      end
    end

    describe :new_datasets_to_submitted do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        # NO -- move into peer_review
        CurationService.new(status: 'peer_review', resource: @res[2], user: @curator, created_at: @day).process
        stats = CurationStats.create(date: @day)
        expect(stats.new_datasets_to_submitted).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day1)

        # NO -- move into curation, but not actually submitted
        create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(0)

        # YES -- move into submitted
        @res[1].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: @res[1], user: @user, created_at: @day1).process
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(1)

        # YES -- move into published
        @res[2].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: @res[2], user: @user, created_at: @day1).process
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day1)
        create(:curation_activity, :published, resource: @res[2], user: @curator, created_at: @day1)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # NO -- was submitted previously
        @res[3].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: @res[3], user: @user, created_at: @day - 2.days).process
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # YES -- but there are two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident')
        res_new = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day1).process
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new2.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new2, user: @curator, created_at: @day1).process
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)

        # NO -- there are two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new3.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new3, user: @curator, created_at: @day1 - 2.days).process
        Timecop.travel(Time.now.utc + 1.minute)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new4.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new4, user: @curator, created_at: @day1).process
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)
        Timecop.return
      end
    end

    describe :new_datasets_to_peer_review do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        # NO -- move into submitted
        CurationService.new(status: 'submitted', resource: @res[2], user: @curator, created_at: @day).process
        stats = CurationStats.create(date: @day)
        expect(stats.new_datasets_to_peer_review).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # NO -- move into curation, but not actually submitted
        create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(0)

        # YES -- move into peer_review
        @res[1].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: @res[1], user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(1)

        # YES -- move into published
        @res[2].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: @res[2], user: @user, created_at: @day).process
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day)
        create(:curation_activity, :published, resource: @res[2], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # NO -- was submitted previously
        @res[3].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: @res[3], user: @user, created_at: @day - 2.days).process
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # YES -- but this dataset has two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: res_new, user: @user, created_at: @day).process
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @user, tenant_id: 'dryad')
        res_new2.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: res_new2, user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # NO -- this dataset has two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new3.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: res_new3, user: @user, created_at: @day - 2.days).process
        Timecop.travel(Time.now.utc + 1.minute)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @user, tenant_id: 'dryad')
        res_new4.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'peer_review', resource: res_new4, user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # YES -- goes through 'submitted' before 'peer_review
        @res[4].resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: @res[4], user: @user, created_at: @day).process
        CurationService.new(status: 'peer_review', resource: @res[4], user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(4)
        Timecop.return
      end
    end

    describe :ppr_to_curation do
      it 'knows when there are none' do
        # NO -- move to submitted after a curation status
        CurationService.new(status: 'peer_review', resource: @res[0], user: @curator, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        create(:curation_activity, :curation, resource: res_new, user: @curator, created_at: @day)
        Timecop.travel(Time.now.utc + 1.minute)
        res_new2 = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        CurationService.new(status: 'submitted', resource: res_new2, user: @curator, created_at: @day).process
        stats = CurationStats.create(date: @day)
        expect(stats.ppr_to_curation).to eq(0)
        Timecop.return
      end

      it 'counts correctly when there are some' do
        # YES -- move to submitted after a PPR status
        CurationService.new(status: 'peer_review', resource: @res[0], user: @curator, created_at: @day).process
        res_new = create(:resource, identifier_id: @res[0].identifier_id, user: @user, tenant_id: 'dryad')
        res_new.resource_states.first.update(resource_state: 'submitted')
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
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
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        # NO -- move into submitted
        CurationService.new(status: 'submitted', resource: @res[2], user: @curator, created_at: @day).process
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_to_aar).to eq(0)
        expect(stats.datasets_to_embargoed).to eq(0)
        expect(stats.datasets_to_published).to eq(0)
        expect(stats.datasets_to_withdrawn).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # NO -- curation to published
        create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day)
        create(:curation_activity, :published, resource: @res[0], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(0)
        expect(stats.datasets_to_published).to eq(1)

        # NO -- peer_review to aar
        CurationService.new(status: 'peer_review', resource: @res[1], user: @curator, created_at: @day).process
        create(:curation_activity, resource: @res[1], status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(0)

        # YES -- curation to aar
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day)
        create(:curation_activity, resource: @res[2], status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(1)

        # YES -- curation to aar, but only count once when it happens twice to the same dataset
        create(:curation_activity, :curation, resource: @res[3], user: @curator, created_at: @day)
        create(:curation_activity, resource: @res[3], status: 'action_required', user: @curator, created_at: @day)
        create(:curation_activity, :curation, resource: @res[3], user: @curator, created_at: @day)
        create(:curation_activity, resource: @res[3], status: 'action_required', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)

        # NO -- was curated previously
        create(:curation_activity, :curation, resource: @res[4], user: @curator, created_at: @day - 2.days)
        create(:curation_activity, resource: @res[4], status: 'action_required', user: @curator, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)

        # NO -- was published by system
        create(:curation_activity, :curation, resource: @res[5], user: @curator, created_at: @day - 2.days)
        create(:curation_activity, :embargoed, resource: @res[5], user: @curator, created_at: @day - 2.days)
        create(:curation_activity, :embargoed, resource: @res[5], user: @curator, created_at: @day - 1.day)
        create(:curation_activity, :published, resource: @res[5], user: @system_user, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_aar).to eq(2)
        expect(stats.datasets_to_published).to eq(1)

        # YES, two withdrawn, from different statuses
        create(:curation_activity, :curation, resource: @res[0], user: @curator, created_at: @day - 1.day)
        create(:curation_activity, :withdrawn, resource: @res[0], user: @curator, created_at: @day)
        CurationService.new(status: 'peer_review', resource: @res[1], user: @curator, created_at: @day - 1.day).process
        create(:curation_activity, :withdrawn, resource: @res[1], user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.datasets_to_withdrawn).to eq(2)
      end
    end

    describe :author_revised do
      it 'knows when there are none' do
        stats = CurationStats.create(date: @day)

        # NO -- move into curation, but not anywhere else (not typical, but could happen)
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        expect(stats.author_revised).to eq(0)

        # NO -- move into curation, but it was previously in AAR
        create(:curation_activity, resource: @res[1], status: 'action_required', user: @curator, created_at: @day)
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        expect(stats.author_revised).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version
        create(:curation_activity, resource: @res[0], status: 'action_required', user: @curator, created_at: @day)
        CurationService.new(status: 'submitted', resource: @res[0], user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.author_revised).to eq(1)

        # YES -- with different versions
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        create(:curation_activity, resource: @res[1], status: 'action_required', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @user, tenant_id: 'dryad')
        CurationService.new(status: 'submitted', resource: res_new, user: @curator, created_at: @day).process
        create(:curation_activity, :curation, resource: res_new, user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_revised).to eq(2)
      end
    end

    describe :author_versioned do
      it 'knows when there are none' do
        # NO -- just a normal submission
        CurationService.new(status: 'submitted', resource: @res[1], user: @user, created_at: @day).process

        stats = CurationStats.create(date: @day)
        expect(stats.author_versioned).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version (unlikely)
        CurationService.new(status: 'submitted', resource: @res[0], user: @user, created_at: @day).process
        create(:curation_activity, :published, resource: @res[0], user: @curator, created_at: @day)
        CurationService.new(status: 'submitted', resource: @res[0], user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.author_versioned).to eq(1)

        # YES -- with different versions submitted on the same day
        create(:curation_activity, :curation, resource: @res[1], user: @curator, created_at: @day)
        create(:curation_activity, :embargoed, resource: @res[1], user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @user, tenant_id: 'dryad')
        CurationService.new(status: 'submitted', resource: res_new, user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.author_versioned).to eq(2)

        # YES -- with different versions submitted on different days
        create(:curation_activity, :curation, resource: @res[2], user: @curator, created_at: @day - 2.days)
        create(:curation_activity, :published, resource: @res[2], user: @curator, created_at: @day - 2.days)
        res_new = create(:resource, identifier_id: @res[2].identifier.id, user: @user, tenant_id: 'dryad')
        CurationService.new(status: 'submitted', resource: res_new, user: @user, created_at: @day).process
        stats.recalculate
        expect(stats.author_versioned).to eq(3)

      end
    end

  end
end
