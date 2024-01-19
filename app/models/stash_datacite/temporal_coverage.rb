# == Schema Information
#
# Table name: stash_datacite_temporal_coverages
#
#  id          :integer          not null, primary key
#  description :text(65535)
#  resource_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module StashDatacite
  class TemporalCoverage < Description
    self.table_name = 'stash_datacite_temporal_coverages'
  end
end
