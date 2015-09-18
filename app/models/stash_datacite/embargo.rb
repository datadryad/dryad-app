module StashDatacite
  class Embargo < ActiveRecord::Base
    self.table_name = "dcs_embargoes"
  end
end
