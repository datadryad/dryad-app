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
        has_many :titles, class_name: 'StashDatacite::Title'
      end
    end
  end
end