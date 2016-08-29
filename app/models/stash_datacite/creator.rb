module StashDatacite
  class Creator < ActiveRecord::Base
    self.table_name = 'dcs_creators'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier, class_name: 'StashDatacite::NameIdentifier', foreign_key: 'name_identifier_id'

    has_and_belongs_to_many :affiliations, class_name: 'StashDatacite::Affiliation'

    amoeba do
      enable
    end

    amoeba do
      enable
    end

    before_save :strip_whitespace

    scope :filled, -> {
      joins(:affiliations)
        .where("TRIM(IFNULL(creator_first_name,'')) <> '' AND TRIM(IFNULL(creator_last_name,'')) <> ''")
    }

    scope :names_filled, -> { where("TRIM(IFNULL(creator_first_name,'')) <> ''") }

    scope :affiliation_filled, -> {
      joins(:affiliations)
        .where("TRIM(IFNULL(dcs_affiliations.long_name,'')) <> ''")
    }

    def creator_full_name
      full_name = [creator_last_name, creator_first_name]
      creator_full_name = full_name.compact.split('').flatten.join(', ')
      creator_full_name
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

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id=(affil_id)
      self.affiliation_ids = affil_id
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id
      affiliation_ids.try(:first)
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation=(affil)
      affiliations.clear
      affiliations << affil
    end

    #this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation
      affiliations.try(:first)
    end

    private

    def strip_whitespace
      self.creator_first_name = creator_first_name.strip unless creator_first_name.nil?
      self.creator_last_name = creator_last_name.strip unless creator_last_name.nil?
    end
  end
end
