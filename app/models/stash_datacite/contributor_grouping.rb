# == Schema Information
#
# Table name: dcs_contributor_groupings
#
#  id                 :bigint           not null, primary key
#  contributor_name   :text(65535)
#  group_label        :string(191)
#  identifier_type    :integer          default("crossref_funder_id")
#  json_contains      :json
#  required           :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name_identifier_id :string(191)
#
module StashDatacite
  class ContributorGrouping < ApplicationRecord
    self.table_name = 'dcs_contributor_groupings'

    enum :identifier_type, {
      isni: 0,
      grid: 1,
      crossref_funder_id: 2,
      ror: 3,
      other: 4
    }

  end
end
