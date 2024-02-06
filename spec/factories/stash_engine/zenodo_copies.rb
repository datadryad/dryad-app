# == Schema Information
#
# Table name: stash_engine_zenodo_copies
#
#  id            :integer          not null, primary key
#  conceptrecid  :string(191)
#  copy_type     :string           default("data")
#  error_info    :text(16777215)
#  note          :text(65535)
#  retries       :integer          default(0)
#  software_doi  :string(191)
#  state         :string           default("enqueued")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deposition_id :integer
#  identifier_id :integer
#  resource_id   :integer
#
# Indexes
#
#  index_stash_engine_zenodo_copies_on_conceptrecid   (conceptrecid)
#  index_stash_engine_zenodo_copies_on_copy_type      (copy_type)
#  index_stash_engine_zenodo_copies_on_deposition_id  (deposition_id)
#  index_stash_engine_zenodo_copies_on_identifier_id  (identifier_id)
#  index_stash_engine_zenodo_copies_on_note           (note)
#  index_stash_engine_zenodo_copies_on_resource_id    (resource_id)
#  index_stash_engine_zenodo_copies_on_retries        (retries)
#  index_stash_engine_zenodo_copies_on_software_doi   (software_doi)
#  index_stash_engine_zenodo_copies_on_state          (state)
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
