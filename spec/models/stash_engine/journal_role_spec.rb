# == Schema Information
#
# Table name: stash_engine_journal_roles
#
#  id                      :integer          not null, primary key
#  journal_id              :integer
#  user_id                 :integer
#  role                    :string(191)
#  created_at              :datetime
#  updated_at              :datetime
#  journal_organization_id :integer
#
require 'rails_helper'

module StashEngine

  RSpec.describe JournalRole, type: :model do

    before(:each) do
      @org = create(:journal_organization)
      @journal1 = create(:journal)
      @journal2 = create(:journal)
      @journal3 = create(:journal, sponsor: @org)
      @user = create(:user)
      @journal_role1 = create(:journal_role, journal: @journal1, user: @user)
      @journal_role2 = create(:journal_role, journal: @journal2, user: @user, role: 'admin')
      @journal_role3 = create(:journal_role, journal: nil, journal_organization: @org, user: @user, role: 'org_admin')
    end

    describe 'basic JournalRoles are supported' do
      it 'allows scoping to just administrators' do
        expect(JournalRole.admins.size).to eql(1)
        expect(JournalRole.admins.first.journal).to eql(@journal2)
      end
    end

    describe 'users associations with journals' do
      it 'returns journals associated directly with the user' do
        expect(@user.journals.size).to eql(2)
        expect(@user.journals).to include(@journal1)
        expect(@user.journals).to include(@journal2)
      end

      it 'returns journals that the user administers' do
        expect(@user.journals_as_admin.size).to eql(2)
        expect(@user.journals_as_admin).to include(@journal2)
        expect(@user.journals_as_admin).to include(@journal3)
      end

    end

  end

end
