# This migration creates the `versions` table, the only schema PT requires.
# All other migrations PT provides are optional.
class CreateVersions < ActiveRecord::Migration[8.0]

  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :paper_trail_versions, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" do |t|
      # Consider using bigint type for performance if you are going to store only numeric ids.
      # t.bigint   :whodunnit
      t.string   :whodunnit

      # Known issue in MySQL: fractional second precision
      # -------------------------------------------------
      #
      # MySQL timestamp columns do not support fractional seconds unless
      # defined with "fractional seconds precision". MySQL users should manually
      # add fractional seconds precision to this migration, specifically, to
      # the `created_at` column.
      # (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
      #
      # MySQL users should also upgrade to at least rails 4.2, which is the first
      # version of ActiveRecord with support for fractional seconds in MySQL.
      # (https://github.com/rails/rails/pull/14359)
      #
      # MySQL users should use the following line for `created_at`
      # t.datetime :created_at, limit: 6
      t.datetime :created_at

      t.string   :item_id,   null: false
      t.string   :item_type, null: false, limit: 191
      t.string   :event,     null: false
      t.json     :object
      t.json     :object_changes
      t.integer  :resource_id
    end

    add_index :paper_trail_versions, %i[item_type item_id]
    add_index :paper_trail_versions, :resource_id
  end
end
