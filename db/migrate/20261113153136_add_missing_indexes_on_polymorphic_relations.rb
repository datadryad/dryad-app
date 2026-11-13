class AddMissingIndexesOnPolymorphicRelations < ActiveRecord::Migration[8.0]
  def change
    add_index :payment_configurations, %i[partner_id partner_type]
    add_index :external_integrations, %i[integrator_id integrator_type]
  end
end
