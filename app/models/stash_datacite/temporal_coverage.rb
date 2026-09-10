# == Schema Information
#
# Table name: stash_datacite_temporal_coverages
#
#  id          :integer          not null, primary key
#  description :text(16777215)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
module StashDatacite
  class TemporalCoverage < Description
    self.table_name = 'stash_datacite_temporal_coverages'
  end
end
