#for monkeypatching shared resource to have associations
module StashDatacite
  module ResourcePatch
    #has_many :titles, class_name: 'StashDatacite::Title'
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
    def self.associate_with_resource(resource)
      resource.instance_eval do
        has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy #optional
        has_many :contributors, class_name: 'StashDatacite::Contributor', dependent: :destroy # optional
        has_many :creators, class_name: 'StashDatacite::Creator', dependent: :destroy # mandatory
        has_many :datacite_dates, class_name: 'StashDatacite::DataciteDate', dependent: :destroy # optional
        has_many :descriptions, class_name: 'StashDatacite::Description', dependent: :destroy #optional
        has_many :embargoes, class_name: 'StashDatacite::Embargo', dependent: :destroy #?
        has_many :geolocations, class_name: 'StashDatacite::Geolocation'
        #has_many :geolocation_boxes, class_name: 'StashDatacite::GeolocationBox', dependent: :destroy # optional
        #has_many :geolocation_places, class_name: 'StashDatacite::GeolocationPlace', dependent: :destroy # optional
        #has_many :geolocation_points, class_name: 'StashDatacite::GeolocationPoint', dependent: :destroy # optional
        has_many :publication_years, class_name: 'StashDatacite::PublicationYear', dependent: :destroy # required
        has_one :publisher, class_name: 'StashDatacite::Publisher', dependent: :destroy # required
        has_many :related_identifiers, class_name: 'StashDatacite::RelatedIdentifier', dependent: :destroy # optional
        has_one :resource_type, class_name: 'StashDatacite::ResourceType', dependent: :destroy # optional
        has_many :rights, class_name: 'StashDatacite::Right', dependent: :destroy # optional
        has_many :sizes, class_name: 'StashDatacite::Size', dependent: :destroy # optional
        has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject',
                                           through: 'StashDatacite::ResourceSubject', dependent: :destroy #optional
        has_many :titles, class_name: 'StashDatacite::Title', dependent: :destroy # required
        has_one :language, class_name: 'StashDatacite::Language', dependent: :destroy #required
        has_many :alternate_identifiers, class_name: 'StashDatacite::AlternateIdentifier', dependent: :destroy #optional
        has_many :formats, class_name: 'StashDatacite::Format', dependent: :destroy #optional
        has_one :version, class_name: 'StashDatacite::Version', dependent: :destroy #optional

        # this enables deep copying of the resource
        amoeba do
          include_association [:contributors, :creators, :datacite_dates, :descriptions, :embargoes, :geolocations,
                               :geolocation_boxes, :geolocation_places, :geolocation_points, :publication_years,
                               :publisher, :related_identifiers, :resource_type, :rights, :sizes, :subjects, :titles]
        end
      end
    end
  end
end
