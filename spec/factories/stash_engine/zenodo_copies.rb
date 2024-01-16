# == Schema Information
#
# Table name: stash_engine_zenodo_copies
#
#  id            :integer          not null, primary key
#  state         :string           default("enqueued")
#  deposition_id :integer
#  error_info    :text(16777215)
#  identifier_id :integer
#  resource_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  retries       :integer          default(0)
#  copy_type     :string           default("data")
#  software_doi  :string(191)
#  conceptrecid  :string(191)
#  note          :text(65535)
#
FactoryBot.define do

  factory :zenodo_copy, class: StashEngine::ZenodoCopy do
    resource

    state { 'enqueued' }
    deposition_id { Faker::Number.number(digits: 5) }
    error_info { nil }
    identifier_id { nil }
    copy_type { 'data' }
    software_doi { "#{rand.to_s[2..6]}/zenodo.#{rand.to_s[2..11]}" }
    conceptrecid { rand.to_s[2..11] }
  end
end
