module StashDatacite
  class Affliation < ActiveRecord::Base
    self.table_name = 'dcs_affliations'
    has_many :creators

    before_save :strip_whitespace

    private
    def strip_whitespace
      self.long_name = self.long_name.strip unless self.long_name.nil?
    end
  end
end
