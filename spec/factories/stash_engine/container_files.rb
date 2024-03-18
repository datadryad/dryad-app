# == Schema Information
#
# Table name: stash_engine_container_files
#
#  id           :bigint           not null, primary key
#  mime_type    :string(191)
#  path         :text(65535)
#  size         :bigint
#  data_file_id :bigint
#
# Indexes
#
#  index_stash_engine_container_files_on_data_file_id  (data_file_id)
#  index_stash_engine_container_files_on_mime_type     (mime_type)
#
FactoryBot.define do
  factory :container_file, class: StashEngine::ContainerFile do
    data_file

    path { Faker::File.file_name }
    mime_type { Faker::File.mime_type }
    size { Faker::Number.between(from: 1, to: 100_000_000) }
  end
end
