require 'byebug'

module Tasks
  module Zenodo
    module Stats

      def self.first_migration
        StashEngine::ZenodoCopy.where("note like '%Sent by migration%'").order(:created_at).first.created_at
      end

      def self.count_remaining
        sql = <<~SQL
          SELECT count(DISTINCT ids.id) as remaining FROM stash_engine_identifiers ids
          LEFT JOIN stash_engine_zenodo_copies cops
          ON ids.id = cops.identifier_id
          WHERE ids.pub_state = 'published'
          AND (cops.id IS NULL OR cops.state != 'finished');
        SQL

        res = ActiveRecord::Base.connection.exec_query(sql)
        res.rows.flatten.first
      end

      def self.count_migrated
        StashEngine::ZenodoCopy.where("note like '%Sent by migration%'").where(state: 'finished').count
      end

      def self.size_migrated
        sql = <<~SQL
          SELECT SUM(ids.`storage_size`) as st_size FROM stash_engine_zenodo_copies cop
          JOIN stash_engine_identifiers ids
          ON cop.identifier_id = ids.`id`
          WHERE cop.note like '%Sent by migration%'
          AND state = 'finished';
        SQL

        res = ActiveRecord::Base.connection.exec_query(sql)
        res.rows.flatten.first
      end

      def self.size_remaining
        sql = <<~SQL
          SELECT sum(ids1.`storage_size`) as store FROM stash_engine_identifiers ids1
          JOIN
            (SELECT DISTINCT ids.id FROM stash_engine_identifiers ids
            LEFT JOIN stash_engine_zenodo_copies cops
            ON ids.id = cops.identifier_id
            WHERE ids.pub_state = 'published'
            AND (cops.id IS NULL OR cops.state != 'finished')) as ids2
            ON ids2.id = ids1.id;
        SQL

        res = ActiveRecord::Base.connection.exec_query(sql)
        res.rows.flatten.first
      end
    end
  end
end
