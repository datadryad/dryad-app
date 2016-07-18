module StashDatacite
  class Description < ActiveRecord::Base
    self.table_name = 'dcs_descriptions'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    DcsDescriptionTypes = %w(Abstract Methods SeriesInformation TableOfContents Other)
    SpecialSauceDescriptionTypes = %w(usage_notes grant_number)

    DescriptionTypesEnum = (DcsDescriptionTypes + SpecialSauceDescriptionTypes).map{|i| [i.downcase.to_sym, i.downcase]}.to_h

    GrantRegex = Regexp.new(/^Data were created with funding from (.+) under grant (.+)$/)

    enum description_type: DescriptionTypesEnum

    # usage_notes is our special sauce for 'other' which is the real value it would take in datacite.xml.  I suspect
    # we also want to prefix the value with "Usage Notes:" in the XML so we can differentiate it.

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
    scope :type_usage_notes, -> { where(description_type: 'usage_notes') }
    scope :type_grant_number, -> { where(description_type: 'grant_number') }

    # the xml description type for DataCite when we've excluded our special sauce
    def description_type_datacite
      return 'Other' if special_sauce_description_type?
      EnumToDcsDescriptions[desription_type]
    end

    # these do not exist in datacite but are our own special sauce
    def special_sauce_description_type?
      SpecialSauceDescriptionTypes.include?(description_type)
    end

    def special_sauce_description_value_extracted
      return nil if description.blank?
      if description_type == 'usage_notes' && description.start_with?('Usage Notes: ')
        return description[13..-1]
      elsif description_type == 'grant_number' && (matches = GrantRegex.match(description))
        return matches[2]
      end
      description
    end

    def set_description_usage_notes(notes)
      self.description_type = 'usage_notes'
      self.description = "Usage Notes: #{notes}"
    end

    def set_description_grant_number(funder, grant)
      self.description_type = 'grant_number'
      self.description = "Data were created with funding from #{funder} under grant #{grant}"
    end

  end
end
