# == Schema Information
#
# Table name: stash_engine_edit_codes
#
#  id         :bigint           not null, primary key
#  applied    :boolean          default(FALSE)
#  edit_code  :string(191)
#  role       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint
#
# Indexes
#
#  index_stash_engine_edit_codes_on_author_id  (author_id)
#  index_stash_engine_edit_codes_on_edit_code  (edit_code)
#
FactoryBot.define do

  factory :edit_code, class: StashEngine::EditCode do
    author
    role

    applied { true }
    edit_code { Faker::Internet.uuid }
  end
end
