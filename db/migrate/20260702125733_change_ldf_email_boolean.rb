class ChangeLdfEmailBoolean < ActiveRecord::Migration[8.0]
  def up
    change_column :payment_configurations, :ldf_limit_notification, :text, default: nil
  end

  def down
    change_column :payment_configurations, :ldf_limit_notification, :boolean, default: false
  end
end
