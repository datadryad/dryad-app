# == Schema Information
#
# Table name: dcs_publication_years
#
#  id               :integer          not null, primary key
#  publication_year :string(191)
#  resource_id      :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do

  factory :publication_year, class: StashDatacite::PublicationYear do

    resource

    publication_year { '2019' }

  end

end
