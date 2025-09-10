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
    let(:resource) { create(:resource) }
    let(:proposed_change) { create(:proposed_change, identifier: resource.identifier) }

    describe ':== (equality)' do
      it 'returns false if the proposed_change passed in is nil' do
        expect(proposed_change.nil?).to eql(false)
      end

      it 'returns false if the proposed_change passed in is not a ProposedChange' do
        expect(proposed_change == { 'title' => 'Foo' }).to eql(false)
      end

      context 'relevant attributes result in a FALSE if they do not match' do
        let(:pc) { proposed_change.dup }

        it 'checking identifier_id' do
          pc.identifier_id = 789_578
          expect(proposed_change == pc).to eql(false)
        end

        it 'checking provenance' do
          pc.provenance = 'some other site'
          expect(@roposed_change == pc).to eql(false)
        end

        it 'checking publication_name' do
          pc.publication_name = 'Foo'
          expect(proposed_change == pc).to eql(false)
        end
        it 'checking publication_issn' do
          pc.publication_issn = nil
          expect(proposed_change == pc).to eql(false)
        end
        it 'checking publication_doi' do
          pc.publication_doi = nil
          expect(proposed_change == pc).to eql(false)
        end
        it 'checking title' do
          pc.title = 'Foo'
          expect(@roposed_change == pc).to eql(false)
        end
      end

      context 'relevant attributes result in a TRUE if they match'
      let(:pc) { proposed_change.dup }

      it 'returns true if all the relevant attributes match' do
        pc.score = 45.342
        pc.approved = true
        expect(proposed_change == pc).to eql(true)
      end
    end

    describe 'approve and reject' do
      let(:user) { create(:user, role: 'manager') }

      context :approve! do
        it 'approves the changes' do
          old_title = resource.title
          proposed_change.approve!(current_user: user, approve_type: 'primary')
          resource.reload

          expect(resource.title).to eql(old_title)
          expect(resource.resource_publication.publication_name).to eql(proposed_change.publication_name)
          expect(resource.identifier.publication_article_doi).to include(proposed_change.publication_doi)

          proposed_change.reload
          expect(proposed_change.approved).to eql(true)
          expect(proposed_change.user).to eql(user)
        end

        it 'does not approve the changes if no user is specified' do
          expect(proposed_change.approve!(current_user: nil, approve_type: 'primary')).to eql(false)
          expect(proposed_change.approve!(current_user: 'John Doe', approve_type: 'primary')).to eql(false)
        end
      end

      context :reject! do
        it 'returns the user' do
          id = proposed_change.id
          identifier = proposed_change.identifier
          proposed_change.reject!(current_user: user)
          expect(StashEngine::ProposedChange.unprocessed.where(id: id).empty?).to eql(true)
          expect(StashEngine::ProposedChange.where(identifier_id: identifier.id).first&.rejected?).to eql(true)
          expect(StashEngine::ProposedChange.where(identifier_id: identifier.id).first&.user_id).to eql(user.id)
        end
      end
    end
  end
end
