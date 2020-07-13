class AddAcceptedAgreementToResource < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :accepted_agreement, :boolean
  end
end
