# == Schema Information
#
# Table name: stash_engine_xref_funder_to_rors
#
#  id       :bigint           not null, primary key
#  xref_id  :string(191)
#  ror_id   :string(191)
#  org_name :text(65535)
#
module StashEngine
  class XrefFunderToRor < ApplicationRecord
    self.table_name = 'stash_engine_xref_funder_to_rors'
  end
end
