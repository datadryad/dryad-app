class AddTriggersForLastCurationActivity < ActiveRecord::Migration[5.2]

  TRIGGER_CURATION_INSERT = <<-SQL
      CREATE TRIGGER trigger_curation_insert AFTER INSERT ON stash_engine_curation_activities
      FOR EACH ROW
      BEGIN
        UPDATE stash_engine_resources
        SET last_curation_activity_id = (
	        SELECT max(id) as max_id
	        FROM stash_engine_curation_activities
	        WHERE resource_id = NEW.resource_id)
        WHERE id = NEW.resource_id;
      END;
  SQL

  TRIGGER_CURATION_UPDATE = <<-SQL
      CREATE TRIGGER trigger_curation_update AFTER UPDATE ON stash_engine_curation_activities
      FOR EACH ROW
      BEGIN
        IF !(NEW.resource_id <=> OLD.resource_id) THEN
          UPDATE stash_engine_resources
          SET last_curation_activity_id = (
	          SELECT max(id) as max_id
	          FROM stash_engine_curation_activities
	          WHERE resource_id = NEW.resource_id)
          WHERE id = NEW.resource_id;
        END IF;
      END;
  SQL

  TRIGGER_CURATION_DELETE = <<-SQL
      CREATE TRIGGER trigger_curation_delete AFTER DELETE ON stash_engine_curation_activities
      FOR EACH ROW
      BEGIN
        UPDATE stash_engine_resources
        SET last_curation_activity_id = (
          SELECT max(id) as max_id
	        FROM stash_engine_curation_activities
	        WHERE resource_id = OLD.resource_id)
        WHERE id = OLD.resource_id;
      END;
  SQL

  def up
    execute <<-SQL
      UPDATE stash_engine_resources
      INNER JOIN
        (SELECT max(id) as max_curation_id, resource_id
        FROM stash_engine_curation_activities
        GROUP BY resource_id) max_curation
      ON stash_engine_resources.id = max_curation.resource_id
      SET stash_engine_resources.last_curation_activity_id = max_curation.max_curation_id;
    SQL

    execute TRIGGER_CURATION_INSERT
    execute TRIGGER_CURATION_UPDATE
    execute TRIGGER_CURATION_DELETE
  end

  def down
    execute 'DROP TRIGGER IF EXISTS trigger_curation_insert'
    execute 'DROP TRIGGER IF EXISTS trigger_curation_update'
    execute 'DROP TRIGGER IF EXISTS trigger_curation_delete'
  end
end
