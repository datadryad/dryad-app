# == Schema Information
#
# Table name: stash_engine_versions
#
#  id              :integer          not null, primary key
#  deleted_at      :datetime
#  merritt_version :integer
#  version         :integer
#  zip_filename    :text(65535)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  resource_id     :integer
#
# Indexes
#
#  index_stash_engine_versions_on_deleted_at   (deleted_at)
#  index_stash_engine_versions_on_resource_id  (resource_id)
#
FactoryBot.define do

  factory :version, class: StashEngine::Version do
    resource
    version { 1 }
    merritt_version { 1 }
    zip_filename { nil }
    deleted_at { nil }
  end
end
