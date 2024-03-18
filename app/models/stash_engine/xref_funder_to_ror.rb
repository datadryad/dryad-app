# == Schema Information
#
# Table name: stash_engine_xref_funder_to_rors
#
#  id       :bigint           not null, primary key
#  org_name :text(65535)
#  ror_id   :string(191)
#  xref_id  :string(191)
#
# Indexes
#
#  index_stash_engine_xref_funder_to_rors_on_ror_id   (ror_id)
#  index_stash_engine_xref_funder_to_rors_on_xref_id  (xref_id)
#
module StashEngine
  class XrefFunderToRor < ApplicationRecord
    self.table_name = 'stash_engine_xref_funder_to_rors'
  end
end
