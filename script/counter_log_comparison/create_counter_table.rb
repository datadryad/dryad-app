class CreateCounterTable < ActiveRecord::Migration[5.2]
  def change
    create_table :counter_log do |table|
      table.timestamp :time, index: true
      table.string :ip
      table.text :url
      table.string :doi, index: true
      table.text :user_agent
      table.string :hit_type, index: true # view or download
      table.boolean :matched, index: true
    end
  end
end

