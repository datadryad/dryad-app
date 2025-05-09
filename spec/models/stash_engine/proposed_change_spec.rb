# == Schema Information
#
# Table name: stash_engine_proposed_changes
#
#  id               :integer          not null, primary key
#  approved         :boolean
#  authors          :text(65535)
#  provenance       :string(191)
#  provenance_score :float(24)
#  publication_date :datetime
#  publication_doi  :string(191)
#  publication_issn :string(191)
#  publication_name :string(191)
#  rejected         :boolean
#  score            :float(24)
#  subjects         :text(65535)
#  title            :text(65535)
#  url              :string(191)
#  xref_type        :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  identifier_id    :integer
#  user_id          :integer
#
# Indexes
#
#  index_stash_engine_proposed_changes_on_identifier_id     (identifier_id)
#  index_stash_engine_proposed_changes_on_publication_doi   (publication_doi)
#  index_stash_engine_proposed_changes_on_publication_issn  (publication_issn)
#  index_stash_engine_proposed_changes_on_publication_name  (publication_name)
#  index_stash_engine_proposed_changes_on_user_id           (user_id)
#
require 'rails_helper'

module StashEngine
  describe ProposedChange do

    before(:each) do

      allow_any_instance_of(Resource).to receive(:submit_to_solr).and_return(true)
      @user = StashEngine::User.create(
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@datadryad.org',
        tenant_id: 'ucop'
      )
      @identifier = StashEngine::Identifier.create(identifier: '10.1234/abcd123')
      @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier_id: @identifier.id)
      @identifier.reload
      allow(StashDatacite::Affiliation).to receive(:find_by_ror_long_name).and_return(nil)

      @params = {
        identifier_id: @identifier.id,
        approved: false,
        authors: [
          { 'ORCID' => 'http://orcid.org/0000-0002-0955-3483', 'given' => 'Julia M.', 'family' => 'Petersen',
            'affiliation' => [{ 'name' => 'Hotel California' }] },
          { 'ORCID' => 'http://orcid.org/0000-0002-1212-2233', 'given' => 'Michelangelo', 'family' => 'Snow',
            'affiliation' => [{ 'name' => 'Catalonia' }] }
        ].to_json,
        provenance: 'crossref',
        publication_date: Date.new(2018, 8, 13),
        publication_doi: '10.1073/pnas.1718211115',
        publication_issn: '1234-1234',
        publication_name: 'Ficticious Journal',
        score: 2.0,
        title: 'High-skilled labour mobility in Europe before and after the 2004 enlargement'
      }
      @proposed_change = StashEngine::ProposedChange.new(@params)
    end

    describe ':== (equality)' do
      it 'returns false if the proposed_change passed in is nil' do
        expect(@proposed_change.nil?).to eql(false)
      end

      it 'returns false if the proposed_change passed in is not a ProposedChange' do
        expect(@proposed_change == { 'title' => 'Foo' }).to eql(false)
      end

      context 'relevant attributes result in a FALSE if they do not match' do
        before(:each) do
          @pc = StashEngine::ProposedChange.new(@params)
        end

        it 'checking identifier_id' do
          @pc.identifier_id = 789_578
          expect(@proposed_change == @pc).to eql(false)
        end

        it 'checking provenance' do
          @pc.provenance = 'some other site'
          expect(@proposed_change == @pc).to eql(false)
        end

        it 'checking publication_name' do
          @pc.publication_name = 'Foo'
          expect(@proposed_change == @pc).to eql(false)
        end
        it 'checking publication_issn' do
          @pc.publication_issn = nil
          expect(@proposed_change == @pc).to eql(false)
        end
        it 'checking publication_doi' do
          @pc.publication_doi = nil
          expect(@proposed_change == @pc).to eql(false)
        end
        it 'checking title' do
          @pc.title = 'Foo'
          expect(@proposed_change == @pc).to eql(false)
        end
      end

      it 'returns true if all the relevant attributes match' do
        pc = StashEngine::ProposedChange.new(@params)
        pc.score = 45.342
        pc.approved = true
        expect(@proposed_change == pc).to eql(true)
      end
    end

    describe :approve! do
      it 'approves the changes' do
        old_title = @resource.title
        @proposed_change.approve!(current_user: @user, approve_type: 'primary')
        @resource.reload

        expect(@resource.title).to eql(old_title)
        expect(@resource.resource_publication.publication_name).to eql(@params[:publication_name])
        expect(@resource.related_identifiers.select do |id|
          id.related_identifier_type == 'doi' && id.relation_type == 'iscitedby'
        end.first&.related_identifier).to eql(StashDatacite::RelatedIdentifier.standardize_doi(@params[:publication_doi]))

        @proposed_change.reload
        expect(@proposed_change.approved).to eql(true)
        expect(@proposed_change.user).to eql(@user)
      end

      it 'does not approve the changes if no user is specified' do
        expect(@proposed_change.approve!(current_user: nil, approve_type: 'primary')).to eql(false)
        expect(@proposed_change.approve!(current_user: 'John Doe', approve_type: 'primary')).to eql(false)
      end
    end

    describe :reject! do
      it 'returns the user tenant ID' do
        id = @proposed_change.id
        identifier = @proposed_change.identifier
        @proposed_change.reject!(current_user: @user)
        expect(StashEngine::ProposedChange.where(id: id).empty?).to eql(true)
        expect(StashEngine::ProposedChange.where(identifier_id: identifier.id).first&.rejected?).to eql(true)
        expect(StashEngine::ProposedChange.where(identifier_id: identifier.id).first&.user_id).to eql(@user.id)
      end
    end

  end
end
