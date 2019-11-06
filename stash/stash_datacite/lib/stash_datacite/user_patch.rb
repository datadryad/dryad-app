module StashDatacite
  # Ensure Author-Affiliation relation & related methods
  # invoked from StashDatacite::Resource::Completions when first needed
  module UserPatch

    def self.patch!
      StashEngine::User.instance_eval do
        belongs_to :affiliation, class_name: 'StashDatacite::Affiliation'
      end
    end

  end
end
