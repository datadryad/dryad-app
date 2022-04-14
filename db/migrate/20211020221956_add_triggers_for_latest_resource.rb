class AddTriggersForLatestResource < ActiveRecord::Migration[5.2]

  TRIGGER_RESOURCE_INSERT = <<-SQL
      CREATE TRIGGER trigger_resource_insert AFTER INSERT ON stash_engine_resources
      FOR EACH ROW
      BEGIN
        UPDATE stash_engine_identifiers
        SET latest_resource_id = (
	        SELECT max(id) as max_id
	        FROM stash_engine_resources
	        WHERE identifier_id = NEW.identifier_id)
        WHERE id = NEW.identifier_id;
      END;
  SQL

  TRIGGER_RESOURCE_UPDATE = <<-SQL
      CREATE TRIGGER trigger_resource_update AFTER UPDATE ON stash_engine_resources
      FOR EACH ROW
      BEGIN
        IF !(NEW.identifier_id <=> OLD.identifier_id) THEN
          UPDATE stash_engine_identifiers
          SET latest_resource_id = (
            SELECT max(id) as max_id
            FROM stash_engine_resources
            WHERE identifier_id = NEW.identifier_id)
          WHERE id = NEW.identifier_id;
        END IF;
      END;
  SQL

  TRIGGER_RESOURCE_DELETE = <<-SQL
      CREATE TRIGGER trigger_resource_delete AFTER DELETE ON stash_engine_resources
      FOR EACH ROW
      BEGIN
        UPDATE stash_engine_identifiers
        SET latest_resource_id = (
          SELECT max(id) as max_id
          FROM stash_engine_resources
          WHERE identifier_id = OLD.identifier_id)
        WHERE id = OLD.identifier_id;
      END;
  SQL

  def up
    # this is sort of large, but just 1) updates all the latest_resource_ids to be correct in stash_engine_identifiers
    # and then 2) defines create, update, delete triggers that will keep them up to date in MySQL
    execute <<-SQL
      UPDATE stash_engine_identifiers
      INNER JOIN
        (SELECT max(id) as max_resource_id, identifier_id
        FROM stash_engine_resources
        GROUP BY identifier_id) max_resources
      ON stash_engine_identifiers.id = max_resources.identifier_id
      SET stash_engine_identifiers.latest_resource_id = max_resources.max_resource_id;
    SQL

    execute TRIGGER_RESOURCE_INSERT
    execute TRIGGER_RESOURCE_UPDATE
    execute TRIGGER_RESOURCE_DELETE
  end

  def down
    execute 'DROP TRIGGER IF EXISTS trigger_resource_insert'
    execute 'DROP TRIGGER IF EXISTS trigger_resource_update'
    execute 'DROP TRIGGER IF EXISTS trigger_resource_delete'
    SQL
  end
end
