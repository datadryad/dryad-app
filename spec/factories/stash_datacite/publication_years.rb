# == Schema Information
#
# Table name: dcs_publication_years
#
#  id               :integer          not null, primary key
#  publication_year :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  resource_id      :integer
#
# Indexes
#
#  index_dcs_publication_years_on_resource_id  (resource_id)
#
FactoryBot.define do

  factory :publication_year, class: StashDatacite::PublicationYear do

    resource

    publication_year { '2019' }

  end

end
