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



        
      end
    end
  end
end
