require 'rails_helper'

module StashEngine

  RSpec.describe JournalRole, type: :model do

    describe 'user should be able to find associated journals' do

      let(:journal) { build(:journal) }
      let(:journal2) { build(:journal) }
      let(:user) { build(:user) }
      let!(:journal_role) { create(:journal_role, journal: journal, user: user) }
      let!(:journal_role2) { create(:journal_role, journal: journal2, user: user, role: 'admin') }

      it 'returns all journals associated with the user' do
        expect(user.journals.size).to eql(2)
      end

      it 'returns the single journal that the user administers' do
        expect(user.journals_as_admin.size).to eql(1)
        expect(user.journals_as_admin.first).to eql(journal2)
      end

    end

  end

end
