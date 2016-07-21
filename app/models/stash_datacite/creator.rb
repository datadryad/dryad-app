module StashDatacite
  class Creator < ActiveRecord::Base
    self.table_name = 'dcs_creators'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier
    belongs_to :affliation

    before_save :strip_whitespace

    scope :filled, -> { joins(:affliation).
        where("TRIM(IFNULL(creator_first_name,'')) <> '' AND TRIM(IFNULL(creator_last_name,'')) <> ''") }

    scope :names_filled, -> { where("TRIM(IFNULL(creator_first_name,'')) <> ''") }


    scope :affliation_filled, -> { joins(:affliation).
        where("TRIM(IFNULL(dcs_affliations.long_name,'')) <> ''") }

    def creator_full_name
      full_name = [creator_last_name, creator_first_name]
      creator_full_name = full_name.compact.split("").flatten.join(", ")
      return creator_full_name
    end

    private
    def strip_whitespace
      self.creator_first_name = self.creator_first_name.strip unless self.creator_first_name.nil?
      self.creator_last_name = self.creator_last_name.strip unless self.creator_last_name.nil?
    end
  end
end
