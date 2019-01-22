# see https://makandracards.com/makandra/1026-simple-database-lock-for-mysql
# Allows use of locks through database, needed for NOID
class CreateLocks < ActiveRecord::Migration
  def change
    create_table :locks do |t|
      t.string :name, :limit => 40
      t.timestamps
    end
    add_index :locks, :name, :unique => true
  end
end
