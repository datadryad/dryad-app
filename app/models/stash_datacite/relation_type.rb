module StashDatacite
  class RelationType < ActiveRecord::Base
    self.table_name = 'dcs_relation_types'
    has_one :related_identifier

    def friendly_relation_name
      return '' if relation_type.nil?
      relation_type.scan(/[A-Z]{1}[a-z]*/).map{|i| i.downcase}.join(' ')
    end
  end
end
