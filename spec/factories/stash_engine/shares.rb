# == Schema Information
#
# Table name: stash_engine_shares
#
#  id            :integer          not null, primary key
#  secret_id     :string(191)
#  resource_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
FactoryBot.define do

  factory :share, class: StashEngine::Share do
    identifier

    secret_id { SecureRandom.uuid }
  end

end
