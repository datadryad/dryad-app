module StashEngine
  describe CurationStats do

    include Mocks::Aws
    include Mocks::CurationActivity
    include Mocks::Datacite
    include Mocks::Ror
    include Mocks::RSolr
    include Mocks::Stripe
    include Mocks::Tenant

    before(:each) do
      mock_aws!
      mock_ror!
      mock_solr!
      mock_datacite!
      mock_stripe!
      mock_tenant!
      neuter_curation_callbacks!

      @curator = create(:user, tenant_id: 'dryad', role: 'superuser')

      # setup some identifiers, each with one resource
      @res = []
      @idents = [
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/123'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/456'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/789'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/abc'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/def')
      ]
      @idents.each do |i|
        @res << create(:resource, identifier_id: i.id, user: @curator, tenant_id: 'dryad')
      end

      @day = Date.today
      @day1 = @day + 1.day + 1.second
      @day2 = @day + 2.days + 1.second
    end

    describe :datasets_curated do
      it 'knows when there are none' do
        # @res[0] stays in_progress
        # NO -- move into curation, but not out
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into published, but on day1
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day1)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day1)
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

    describe :new_datasets_to_submitted do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into peer_review
        @res[2].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.new_datasets_to_submitted).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # NO -- move into curation, but not actually submitted
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(0)

        # YES -- move into submitted
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(1)

        # YES -- move into published
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # NO -- was submitted previously
        @res[3].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(2)

        # YES -- but there are two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident')
        res_new = create(:resource, identifier_id: id_new.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @curator, tenant_id: 'dryad')
        res_new2.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)

        # NO -- there are two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @curator, tenant_id: 'dryad')
        res_new3.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day - 2.days)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @curator, tenant_id: 'dryad')
        res_new4.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_submitted).to eq(3)

      end
    end

    describe :new_datasets_to_peer_review do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywere else (not typical, but could happen)
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
        @res[1].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(1)

        # YES -- move into published
        @res[2].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # NO -- was submitted previously
        @res[3].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day - 2.days)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(2)

        # YES -- but this dataset has two resources, and only one should count
        id_new = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new = create(:resource, identifier_id: id_new.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        res_new2 = create(:resource, identifier_id: id_new.id, user: @curator, tenant_id: 'dryad')
        res_new2.curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # NO -- this dataset has two resources, and the first was submitted before the target day
        id_new2 = create(:identifier, identifier_type: 'DOI', identifier: '10.123/two_resource_ident_prev_submission')
        res_new3 = create(:resource, identifier_id: id_new2.id, user: @curator, tenant_id: 'dryad')
        res_new3.curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day - 2.days)
        res_new4 = create(:resource, identifier_id: id_new2.id, user: @curator, tenant_id: 'dryad')
        res_new4.curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(3)

        # YES -- goes through 'submitted' before 'peer_review
        @res[4].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[4].curation_activities << CurationActivity.create(status: 'peer_review', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.new_datasets_to_peer_review).to eq(4)

      end
    end

    # Test the fields of format `datasets_to_XXXXX`
    # Focus on the `aar` field, with occasional test of the others, since they use
    # essentially the same calculation.
    describe :datasets_to_some_status do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # NO -- move into submitted
        @res[2].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_to_aar).to eq(0)
        expect(stats.datasets_to_embargoed).to eq(0)
        expect(stats.datasets_to_published).to eq(0)
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

        expect(stats.datasets_to_published).to eq(1)
      end
    end

    describe :author_revised do
      it 'knows when there are none' do
        # NO -- move into curation, but not anywere else (not typical, but could happen)
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)

        stats = CurationStats.create(date: @day)
        expect(stats.author_revised).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version
        @res[0].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_revised).to eq(1)

        # YES -- with different versions
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'action_required', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_revised).to eq(2)
      end
    end

    describe :author_versioned do
      it 'knows when there are none' do
        # NO -- just a normal submission
        @res[1].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)

        stats = CurationStats.create(date: @day)
        expect(stats.author_versioned).to eq(0)
      end

      it 'counts correctly when there are some' do
        stats = CurationStats.create(date: @day)

        # YES -- within the same version (unlikely)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        @res[0].curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(1)

        # YES -- with different versions submitted on the same day
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[1].curation_activities << CurationActivity.create(status: 'embargoed', user: @curator, created_at: @day)
        res_new = create(:resource, identifier_id: @res[1].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(2)

        # YES -- with different versions submitted on different days
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day - 2.days)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day - 2.days)
        res_new = create(:resource, identifier_id: @res[2].identifier.id, user: @curator, tenant_id: 'dryad')
        res_new.curation_activities << CurationActivity.create(status: 'submitted', user: @curator, created_at: @day)
        stats.recalculate
        expect(stats.author_versioned).to eq(3)

      end
    end

  end
end
