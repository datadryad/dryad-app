module StashDatacite
  module IdentifierPatch
    # This patches the identifier class to have a proposed_change.
    def self.associate_with_identifier(identifier_class)
      resource_class.instance_eval do

        # required relations
        has_one :proposed_change, class_name: 'StashDatacite::ProposedChange', dependent: :destroy

        amoeba do
          include_association proposed_change
        end
      end
    end
  end
end
