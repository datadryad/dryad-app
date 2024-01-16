# == Schema Information
#
# Table name: stash_engine_versions
#
#  id              :integer          not null, primary key
#  version         :integer
#  zip_filename    :text(65535)
#  resource_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  merritt_version :integer
#
FactoryBot.define do

  factory :version, class: StashEngine::Version do
    resource
    version { 1 }
    merritt_version { 1 }
    zip_filename { nil }
  end
end
