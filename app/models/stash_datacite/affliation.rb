module StashDatacite
  class Affliation < ActiveRecord::Base
    self.table_name = 'dcs_affliations'
    has_many :creators
  end
end
