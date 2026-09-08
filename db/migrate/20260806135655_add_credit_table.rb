class AddCreditTable < ActiveRecord::Migration[8.0]
  def change
    create_table :dcs_credit_roles do |t|
      t.string :credit_id
      t.string :credit_role
      t.string :contributor_type
      t.text :description
      t.timestamps
    end

    create_table :dcs_credit_roles_authors do |t|
      t.integer :author_id
      t.integer :credit_role_id
      t.timestamps
    end
    add_index :dcs_credit_roles_authors, :author_id
    add_index :dcs_credit_roles_authors, :credit_role_id
  end
end
