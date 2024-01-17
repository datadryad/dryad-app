# == Schema Information
#
# Table name: dcs_rights
#
#  id          :integer          not null, primary key
#  rights      :text(65535)
#  rights_uri  :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do

  factory :right, class: StashDatacite::Right do
    resource

    rights { 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication' }
    rights_uri { 'https://creativecommons.org/publicdomain/zero/1.0/' }
  end

end
