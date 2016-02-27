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
    def self.associate_with_resource(resource)
      resource.instance_eval do
        # has_many :affliations, class_name: 'StashDatacite::Affliation'
        has_many :contributors, class_name: 'StashDatacite::Contributor'
        has_many :creators, class_name: 'StashDatacite::Creator'
        has_many :dates, class_name: 'StashDatacite::Date'
        has_many :descriptions, class_name: 'StashDatacite::Description'
        has_many :embargoes, class_name: 'StashDatacite::Embargo'
        has_many :geolocation_boxes, class_name: 'StashDatacite::GeolocationBox'
        has_many :geolocation_places, class_name: 'StashDatacite::GeolocationPlace'
        has_many :geolocation_points, class_name: 'StashDatacite::GeolocationPoint'
        has_many :publication_years, class_name: 'StashDatacite::PublicationYear'
        has_many :publishers, class_name: 'StashDatacite::Publisher'
        has_many :related_identifiers, class_name: 'StashDatacite::RelatedIdentifier'
        has_many :resource_types, class_name: 'StashDatacite::ResourceType'
        has_many :rights, class_name: 'StashDatacite::Right'
        has_many :sizes, class_name: 'StashDatacite::Size'
        has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject', through: 'StashDatacite::ResourceSubject'
        has_many :titles, class_name: 'StashDatacite::Title'
        has_many :versions, class_name: 'StashDatacite::Version'
      end
    end
  end
end