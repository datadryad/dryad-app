class AddAcceptedAgreementToResource < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :accepted_agreement, :boolean
  end
end
