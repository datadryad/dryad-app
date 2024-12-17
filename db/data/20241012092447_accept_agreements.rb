# frozen_string_literal: true

class AcceptAgreements < ActiveRecord::Migration[7.0]
  def up
    # When a submitter accepts the Dryad terms in order to submit, this should be reflected in the database
    StashEngine::Resource.submitted.where(accepted_agreement: nil).update_all(accepted_agreement: true)
    StashEngine::Resource.joins(:stash_version).where('version > 1').update_all(accepted_agreement: true)
  end

  def down
    # this data migration fixes missing data, no reverse is needed
  end
end
