# == Schema Information
#
# Table name: stash_engine_funder_roles
#
#  id          :bigint           not null, primary key
#  funder_name :string(191)
#  role        :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  funder_id   :string(191)
#  user_id     :bigint
#
# Indexes
#
#  index_stash_engine_funder_roles_on_user_id  (user_id)
#
require 'rails_helper'

module StashEngine

  RSpec.describe FunderRole, type: :model do

    before(:each) do
      @user = create(:user)
      @funder_role1 = create(:funder_role, user: @user)
      @funder_role2 = create(:funder_role, user: @user)
      @res = create(:resource)
    end

    describe 'users as funder admins' do
      it 'returns funders that the user administers' do
        expect(@user.funders_as_admin.size).to eql(2)
        expect(@user.funders_as_admin.map(&:funder_id)).to include(@funder_role1.funder_id)
        expect(@user.funders_as_admin.map(&:funder_id)).to include(@funder_role2.funder_id)

      end

      it 'disallows admin when resource has no funder' do
        expect(@res.admin_for_this_item?(user: @user)).to be_falsey
      end

      it 'allows admin when resource has the same funder' do
        @res.contributors << create(:contributor, resource: @res, name_identifier_id: @funder_role1.funder_id)
        expect(@res.admin_for_this_item?(user: @user)).to be_truthy
      end

      it 'disallows admin when resource has a different funder' do
        @res.contributors << create(:contributor, resource: @res, name_identifier_id: 'non-matching funder ID')
        expect(@res.admin_for_this_item?(user: @user)).to be_falsey
        #### TODO
      end

    end

  end

end
