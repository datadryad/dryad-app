# This migration comes from stash_datacite (originally 20150918183544)
class CreateDcsRelatedIdentifierTypes < ActiveRecord::Migration
  def change
    create_table :dcs_related_identifier_types do |t|
      t.string :related_identifier_type

      t.timestamps null: false
    end
  end
end
