# for monkeypatching shared resource to have associations
module StashDatacite
  module ResourcePatch
    # This patches the resource class to have associations and convenience methods.
    # I'm putting them here since the resource may be used by different metadata
    # engines.  It makes sense for the engine to know a little something about the main
    # application since it will remain constant while an engine may change.
    #
    # The designers of a new metadata engine will need to do some set-up to design it
    # to work with Stash, but a user should not have to configure associations for
    # an engine.
    #
    # We could add methods to a class more directly if we were not defining the shared resource
    # class in the configuration.  As it is, it's problematic to change the class until being
    # certain that the configuration is loaded and so the resource class is defined.  We could
    # probably make it straight forward if we didn't allow the shared resource class to be user-configurable.
    # TODO: just hard-code the resource class and call this when first needed (cf. AuthorPatch)
    def self.associate_with_resource(resource_class)
      resource_class.instance_eval do

        # required relations
        has_many :publication_years, class_name: 'StashDatacite::PublicationYear', dependent: :destroy
        has_one :publisher, class_name: 'StashDatacite::Publisher', dependent: :destroy
        has_one :language, class_name: 'StashDatacite::Language', dependent: :destroy

        # optional relations
        has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy
        has_many :contributors, class_name: 'StashDatacite::Contributor', dependent: :destroy
        has_many :datacite_dates, class_name: 'StashDatacite::DataciteDate', dependent: :destroy
        has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy
        has_many :geolocations, class_name: 'StashDatacite::Geolocation', dependent: :destroy
        has_many :temporal_coverages, class_name: 'StashDatacite::TemporalCoverage', dependent: :destroy
        has_many :related_identifiers, class_name: 'StashDatacite::RelatedIdentifier', dependent: :destroy
        has_one :resource_type, class_name: 'StashDatacite::ResourceType', dependent: :destroy
        has_many :rights, class_name: 'StashDatacite::Right', dependent: :destroy
        has_many :sizes, class_name: 'StashDatacite::Size', dependent: :destroy
        has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject', through: 'StashDatacite::ResourceSubject', dependent: :destroy
        has_many :alternate_identifiers, class_name: 'StashDatacite::AlternateIdentifier', dependent: :destroy
        has_many :formats, class_name: 'StashDatacite::Format', dependent: :destroy
        has_one :version, class_name: 'StashDatacite::Version', dependent: :destroy

        amoeba do
          # can't just pass the array to include_association() or it clobbers the ones defined in stash_engine
          # see https://github.com/amoeba-rb/amoeba/issues/76
          %i[contributors datacite_dates descriptions geolocations temporal_coverages
             publication_years publisher related_identifiers resource_type rights sizes
             subjects].each do |assoc|
            include_association assoc
          end
        end
      end
    end
  end
end
