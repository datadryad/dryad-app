# == Schema Information
#
# Table name: stash_engine_container_files
#
#  id           :bigint           not null, primary key
#  data_file_id :bigint
#  path         :text(65535)
#  mime_type    :string(191)
#  size         :bigint
#
FactoryBot.define do
  factory :container_file, class: StashEngine::ContainerFile do
    data_file

    path { Faker::File.file_name }
    mime_type { Faker::File.mime_type }
    size { Faker::Number.between(from: 1, to: 100_000_000) }
  end
end
