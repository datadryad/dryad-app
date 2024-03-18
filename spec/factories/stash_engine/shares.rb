# == Schema Information
#
# Table name: stash_engine_shares
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#  resource_id   :integer
#  secret_id     :string(191)
#
# Indexes
#
#  index_stash_engine_shares_on_identifier_id  (identifier_id)
#  index_stash_engine_shares_on_secret_id      (secret_id)
#
FactoryBot.define do

  factory :share, class: StashEngine::Share do
    identifier

    secret_id { SecureRandom.uuid }
  end

end
