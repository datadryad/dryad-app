module StashDatacite
  class Description < ActiveRecord::Base
    self.table_name = 'dcs_descriptions'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum description_type: { abstract: 'abstract', methods: 'methods', usage_notes: 'usage_notes' }
    enum description_type: { abstract: 'abstract', methods: 'methods', seriesinformation: 'seriesinformation',
            tableofcontents: 'tableofcontents', other: 'other', usage_notes: 'usage_notes'}
    #%w(Abstract Methods SeriesInformation TableOfContents Other)

    # usage_notes is our special sauce for 'other' which is the real value it would take in datacite.xml.  I suspect
    # we also want to prefix the value with "Usage Notes:" in the XML so we can differentiate it.
    #

    enum description_type: { abstract: 'abstract', methods: 'methods', seriesinformation: 'seriesinformation',
            tableofcontents: 'tableofcontents', other: 'other', usage_notes: 'usage_notes'}

    # scopes for description_type
    scope :type_abstract, -> { where(description_type: 'abstract') }
    scope :type_methods, -> { where(description_type: 'methods') }
    scope :type_usage_notes, -> { where(description_type: 'usage_notes') }
  end
end
