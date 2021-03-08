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

      ### 3 identifiers, which each have 3 resources
      @res = []
      @idents = [
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/123'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/456'),
        create(:identifier, identifier_type: 'DOI', identifier: '10.123/789')
      ]
      @idents.each do |i|
        @res << create(:resource, identifier_id: i.id, user: @curator, tenant_id: 'dryad')
        @res << create(:resource, identifier_id: i.id, user: @curator, tenant_id: 'dryad')
        @res << create(:resource, identifier_id: i.id, user: @curator, tenant_id: 'dryad')
      end

      @day = Date.today
      @day1 = @day + 1.day + 1.second
      @day2 = @day + 2.days + 1.second
    end

    describe :datasets_curated do
      it 'knows when there are none' do
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
        @res[1].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        # YES -- move into published
        @res[2].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[2].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        # YES -- move into embargoed
        @res[5].curation_activities << CurationActivity.create(status: 'curation', user: @curator, created_at: @day)
        @res[5].curation_activities << CurationActivity.create(status: 'published', user: @curator, created_at: @day)
        stats = CurationStats.create(date: @day)
        expect(stats.datasets_curated).to eq(2)
      end
    end

  end
end
