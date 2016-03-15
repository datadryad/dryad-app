module StashDatacite
  class Creator < ActiveRecord::Base
    self.table_name = 'dcs_creators'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier
    belongs_to :affliation


    def creator_full_name
      "#{self.creator_first_name} #{self.creator_last_name}".strip
    end

  end
end
