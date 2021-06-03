require_dependency "stash_engine/application_controller"

module StashEngine
  class ZenodoQueueController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser

    ALLOWED_SORT = %w[id identifier_id resource_id state updated_at copy_type size error_info]
    ALLOWED_ORDER = %w[asc desc]
    def index

      sort = (ALLOWED_SORT & [params[:sort]]).first || 'identifier_id'
      order = (ALLOWED_ORDER & [params[:direction]]).first || 'asc'
      sql = <<~SQL
        SELECT *,
          CASE
            WHEN copy_type LIKE '%software%' THEN
              (SELECT sum(upload_file_size) FROM stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state != 'deleted' AND type = 'StashEngine::SoftwareFile')
            WHEN copy_type LIKE '%supp%' THEN
              (SELECT sum(upload_file_size) from stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state != 'deleted' AND type = 'StashEngine::SuppFile')
            ELSE
              (SELECT sum(upload_file_size) FROM stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state != 'deleted' AND type = 'StashEngine::DataFile')
          END as size
        FROM stash_engine_zenodo_copies
        WHERE state != "finished"
        ORDER BY #{sort} #{order};
      SQL
      @zenodo_copies = ZenodoCopy.find_by_sql(sql)
    end
  end
end
