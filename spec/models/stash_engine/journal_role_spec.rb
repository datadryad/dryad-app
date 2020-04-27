require 'rails_helper'

module StashEngine

  RSpec.describe JournalRole, type: :model do

    before(:each) do
      @journal = build(:journal)
      @journal2 = build(:journal)
      @user = build(:user)
      @journal_role = create(:journal_role, journal: @journal, user: @user)
      @journal_role2 = create(:journal_role, journal: @journal2, user: @user, role: 'admin')
    end

    describe 'basic JournalRoles are supported' do
      it 'allows scoping to just administrators' do
        expect(JournalRole.admins.size).to eql(1)
        expect(JournalRole.admins.first.journal).to eql(@journal2)
      end
    end

    describe 'users are associated with journals' do
      it 'returns all journals associated with the user' do
        expect(@user.journals.size).to eql(2)
      end

      it 'returns the single journal that the user administers' do
        expect(@user.journals_as_admin.size).to eql(1)
        expect(@user.journals_as_admin.first).to eql(@journal2)
      end

    end

  end

end
