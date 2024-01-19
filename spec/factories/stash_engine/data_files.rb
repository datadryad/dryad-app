# == Schema Information
#
# Table name: stash_engine_generic_files
#
#  id                  :integer          not null, primary key
#  upload_file_name    :text(65535)
#  upload_content_type :text(65535)
#  upload_file_size    :bigint
#  resource_id         :integer
#  upload_updated_at   :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  validated_at        :datetime
#  file_state          :string(7)
#  url                 :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  original_url        :text(65535)
#  cloud_service       :string(191)
#  digest              :string(191)
#  digest_type         :string(8)
#  description         :text(65535)
#  original_filename   :text(65535)
#  type                :string(191)
#  compressed_try      :integer          default(0)
#
FactoryBot.define do

  factory :data_file, class: StashEngine::DataFile do
    resource

    upload_file_name { File.basename(Faker::File.file_name) }
    upload_content_type { Faker::File.mime_type }
    upload_file_size { Faker::Number.between(from: 1, to: 100_000_000) }
    file_state { 'created' }
  end
end
