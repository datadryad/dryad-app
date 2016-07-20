module StashDatacite
  class Creator < ActiveRecord::Base
    self.table_name = 'dcs_creators'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier
    belongs_to :affliation

    before_save :strip_whitespace

    scope :filled, -> { joins(:affliation).
        where("TRIM(IFNULL(creator_first_name,'')) <> '' AND TRIM(IFNULL(creator_last_name,'')) <> ''") }

    scope :names_filled, -> { where("TRIM(IFNULL(creator_first_name,'')) <> '' AND TRIM(IFNULL(creator_last_name,'')) <> ''") }


    scope :affliation_filled, -> { joins(:affliation).
        where("TRIM(IFNULL(dcs_affliations.long_name,'')) <> ''") }

    def creator_full_name
      "#{creator_last_name}, #{creator_first_name}".strip
    end

    # convenience methods to set orcid name identifier
    def orcid_id=(orcid)
      #remove if not set and an orcid exists
      if orcid.blank? && !name_identifier_id.blank? && name_identifier.name_identifier_scheme == 'ORCID'
        self.name_identifier_id = nil
        return
      end
      name_id = NameIdentifier.find_or_create_by(name_identifier: orcid, name_identifier_scheme: 'ORCID') do |ni|
        ni.name_identifier_scheme = 'ORCID'
        ni.scheme_URI = 'http://orcid.org'
      end
      self.name_identifier_id = name_id.id
    end

    def orcid_id
      return nil if name_identifier_id.blank? || name_identifier.name_identifier_scheme != 'ORCID'
      name_identifier.name_identifier
    end

    private
    def strip_whitespace
      self.creator_first_name = self.creator_first_name.strip unless self.creator_first_name.nil?
      self.creator_last_name = self.creator_last_name.strip unless self.creator_last_name.nil?
    end
  end
end
