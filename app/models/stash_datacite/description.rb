# frozen_string_literal: true

module StashDatacite
  class Description < ApplicationRecord
    self.table_name = 'dcs_descriptions'
    belongs_to :resource, class_name: StashEngine::Resource.to_s

    DescriptionTypes = Datacite::Mapping::DescriptionType.map(&:value)

    DescriptionTypesEnum = DescriptionTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    DescriptionTypesStrToFull = DescriptionTypes.to_h { |i| [i.downcase, i] }

    # GrantRegex = Regexp.new(/^Data were created with funding from (.+) under grant (.+)$/)

    enum description_type: DescriptionTypesEnum

    # usage_notes is our special sauce for 'other' which is the real value it would take in datacite.xml.  I suspect
    # we also want to prefix the value with "Usage notes:" in the XML so we can differentiate it.

    # The grant_number is always in the form "Data were created with funding from <funder> under grant <grant>".
    # However, it could become awful to differentiate grants only based on this string in the database since there
    # can be multiple grants in a form.  It also seems reasonable to put at least part of it as a contributor of type
    # funder, but unfortunately we can't put an arbitrary local identifier into that one, so Bhavi had added an
    # award_number to the table.
    #
    # I don't think this is actually too unreasonable for our special sauce and then rather than writing it into the
    # awkward string every time we save it in the DB, we can simply write this string into Desription with type other
    # on export to DataCite XML for items with that award_number.

    # scopes for description_type
    scope :type_abstract, -> { where(description_type: 'abstract') }
    scope :type_methods, -> { where(description_type: 'methods') }
    scope :type_technical_info, -> { where(description_type: 'technicalinfo') }
    scope :type_other, -> { where(description_type: 'other') }

    # the xml description type for DataCite when we've excluded our special sauce

    def description_type_friendly=(type)
      self.description_type = type.to_s.downcase unless type.blank?
    end

    def description_type_friendly
      return nil if description_type.blank?

      DescriptionTypesStrToFull[description_type]
    end

    def self.description_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::DescriptionType.find_by_value(str)
    end

    def description_type_mapping_obj
      return nil if description_type_friendly.nil?

      Description.description_type_mapping_obj(description_type_friendly)
    end

    def update_search_words
      resource&.identifier&.update_search_words! if description_type == 'abstract' && saved_change_to_description?
    end

    after_save :update_search_words
  end
end
