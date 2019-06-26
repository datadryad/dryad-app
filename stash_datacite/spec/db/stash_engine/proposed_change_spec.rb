require 'db_spec_helper'

module StashEngine
  describe ProposedChange do

    before(:each) do
      allow_any_instance_of(Resource).to receive(:submit_to_solr).and_return(true)
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        tenant_id: 'ucop'
      )
      @identifier = StashEngine::Identifier.create(identifier: '10.1234/abcd123')
      @resource = StashEngine::Resource.create(user_id: @user.id, tenant_id: 'ucop', identifier_id: @identifier.id)
      # allow_any_instance_of(Stash::Organization::Ror).to receive(:find_first_by_ror_name).and_return(id: 'abcd', name: 'Hotel California')
      allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)

      @params = {
        identifier_id: @identifier.id,
        approved: false,
        authors: [
          { 'ORCID' => 'http://orcid.org/0000-0002-0955-3483', 'given' => 'Julia M.', 'family' => 'Petersen',
            'affiliation' => ['name' => 'Hotel California'] },
          { 'ORCID' => 'http://orcid.org/0000-0002-1212-2233', 'given' => 'Michelangelo', 'family' => 'Snow',
            'affiliation' => ['name' => 'Catalonia'] }
        ].to_json,
        provenance: 'crossref',
        publication_date: Date.new(2018, 01, 01),
        publication_doi: '10.1073/pnas.1718211115',
        publication_name: 'Ficticious Journal',
        score: 2.0,
        title: 'High-skilled labour mobility in Europe before and after the 2004 enlargement'
      }
      @proposed_change = StashEngine::ProposedChange.new(@params)
    end

    describe :approve! do
      it 'approves the changes' do
        @proposed_change.approve!(current_user: @user)
        @resource.reload

p @resource.publication_date
p @resource.publication_date.class.name

        expect(@resource.title).to eql(@params[:title])
        auths = JSON.parse(@params[:authors])
        expect(@resource.authors.first.author_first_name).to eql(auths.first['given'])
        expect(@resource.authors.first.author_last_name).to eql(auths.first['family'])
        expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationName' }.first.value).to eql(@params[:publication_name])
        expect(@resource.identifier.internal_data.select{ |id| id.data_type == 'publicationDOI' }.first.value).to eql(@params[:publication_doi])
        expect(@resource.publication_date.to_date).to eql(@params[:publication_date])
        expect(@resource.current_curation_status).to eql('published')
        expect(@resource.current_curation_activity.note).to eql('Crossref reported that the related journal has been published')

        @proposed_change.reload
        expect(@proposed_change.approved).to eql(true)
        expect(@proposed_change.user).to eql(@user)
      end

      it 'does not approve the changes if no user is specified' do
        expect(@proposed_change.approve!(current_user: nil)).to eql(false)
        expect(@proposed_change.approve!(current_user: 'John Doe')).to eql(false)
      end
    end

    describe :reject! do
      it 'returns the user tenant ID' do
        id = @proposed_change.id
        identifier = @proposed_change.identifier
        @proposed_change.reject!
        expect(StashEngine::ProposedChange.where(id: id).empty?).to eql(true)
        expect(StashEngine::ProposedChange.where(identifier_id: identifier.id).empty?).to eql(true)
      end
    end

  end
end
