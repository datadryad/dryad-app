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
FactoryBot.define do

  factory :role, class: StashEngine::Role do
    transient { role_object { nil } }

    user
    role { 'admin' }
    role_object_type { role_object&.class&.name || nil }
    role_object_id { role_object&.id || nil }

  end
end
