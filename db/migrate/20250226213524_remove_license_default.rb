class RemoveLicenseDefault < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL.freeze
          ALTER TABLE `stash_engine_identifiers` ALTER COLUMN `license_id` DROP DEFAULT;
        SQL
      end
      dir.down do
        execute <<-SQL.freeze
          ALTER TABLE `stash_engine_identifiers` ALTER COLUMN `license_id` SET DEFAULT 'cc0';
        SQL
      end
    end
  end
end
