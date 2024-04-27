# == Schema Information
#
# Table name: stash_engine_roles
#
#  id               :bigint           not null, primary key
#  role             :string(191)
#  role_object_type :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  role_object_id   :string(191)
#  user_id          :integer
#
# Indexes
#
#  index_stash_engine_roles_on_role_object_type_and_role_object_id  (role_object_type,role_object_id)
#  index_stash_engine_roles_on_user_id                              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => stash_engine_users.id)
#
require 'rails_helper'

module StashEngine

  RSpec.describe Role, type: :model do

    describe 'users as tenant admins' do

      before(:each) do
        @tenant = create(:tenant_dryad)
        @user = create(:user, tenant_id: @tenant.id, role: 'admin', role_object: @tenant)
        @res = create(:resource)
      end

      it 'allows admin when resource has the same tenant' do
        @res.update(tenant_id: @tenant.id)
        expect(@res.admin_for_this_item?(user: @user)).to be_truthy
      end

      it 'disallows admin when resource has a different tenant' do
        expect(@res.admin_for_this_item?(user: @user)).to be_falsey
      end
    end

    describe 'users as funder admins' do

      before(:each) do
        @user = create(:user)
        @funder1 = create(:funder)
        @funder2 = create(:funder)
        create(:role, role_object: @funder1, user: @user)
        create(:role, role_object: @funder2, user: @user)
        @res = create(:resource)
      end

      it 'returns funders that the user administers' do
        expect(@user.funders.size).to eql(2)
        expect(@user.funders.map(&:ror_id)).to include(@funder1.ror_id)
        expect(@user.funders.map(&:ror_id)).to include(@funder2.ror_id)

      end

      it 'disallows admin when resource has no funder' do
        expect(@res.admin_for_this_item?(user: @user)).to be_falsey
      end

      it 'allows admin when resource has the same funder' do
        @res.contributors << create(:contributor, resource: @res, name_identifier_id: @funder1.ror_id)
        expect(@res.admin_for_this_item?(user: @user)).to be_truthy
      end

      it 'disallows admin when resource has a different funder' do
        @res.contributors << create(:contributor, resource: @res, name_identifier_id: 'https://ror.org/nomatch')
        expect(@res.admin_for_this_item?(user: @user)).to be_falsey
      end

    end

    describe 'users as journal admins' do

      before(:each) do
        @org = create(:journal_organization)
        @journal1 = create(:journal)
        @journal2 = create(:journal)
        @journal3 = create(:journal, sponsor: @org)
        @user = create(:user)
        create(:role, role_object: @journal1, user: @user, role: 'curator')
        create(:role, role_object: @journal2, user: @user)
        create(:role, role_object: @org, user: @user)
      end

      describe 'basic journal roles are supported' do
        it 'allows scoping to just administrators' do
          expect(Role.journal_roles.admin.size).to eql(1)
          expect(Role.journal_roles.admin.first.journal).to eql(@journal2)
        end
      end

      describe 'users associations with journals' do
        it 'returns journals associated directly with the user' do
          expect(@user.journals.size).to eql(2)
          expect(@user.journals).to include(@journal1)
          expect(@user.journals).to include(@journal2)
        end

        it 'returns journals that the user administers' do
          expect(@user.journals_as_admin.size).to eql(3)
          expect(@user.journals_as_admin).to include(@journal2)
          expect(@user.journals_as_admin).to include(@journal3)
        end

      end

    end

  end

end
