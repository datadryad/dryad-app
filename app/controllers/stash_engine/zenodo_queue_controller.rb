module StashEngine
  class ZenodoQueueController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser

    ALLOWED_SORT = %w[id identifier_id resource_id state updated_at copy_type size error_info].freeze
    ALLOWED_ORDER = %w[asc desc].freeze

    BASIC_SQL = <<~SQL.freeze
      SELECT *,
          CASE
            WHEN copy_type LIKE '%software%' THEN
              (SELECT sum(upload_file_size) FROM stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state = 'created' AND type = 'StashEngine::SoftwareFile')
            WHEN copy_type LIKE '%supp%' THEN
              (SELECT sum(upload_file_size) from stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state = 'created' AND type = 'StashEngine::SuppFile')
            ELSE
              (SELECT sum(upload_file_size) FROM stash_engine_generic_files
                WHERE resource_id = stash_engine_zenodo_copies.resource_id AND file_state != 'deleted' AND type = 'StashEngine::DataFile')
          END as size
        FROM stash_engine_zenodo_copies
    SQL

    def index
      sort = (ALLOWED_SORT & [params[:sort]]).first || 'identifier_id'
      order = (ALLOWED_ORDER & [params[:direction]]).first || 'asc'
      sql = <<~SQL
        #{BASIC_SQL}
        WHERE state != "finished"
        ORDER BY #{sort} #{order};
      SQL
      @zenodo_copies = ZenodoCopy.find_by_sql(sql)
    end

    def item_details
      @zenodo_copy = ZenodoCopy.find(params[:id])

      @delayed_jobs = running_jobs(@zenodo_copy)
    end

    def identifier_details
      sort = (ALLOWED_SORT & [params[:sort]]).first || 'identifier_id'
      order = (ALLOWED_ORDER & [params[:direction]]).first || 'asc'
      sql = <<~SQL
        #{BASIC_SQL}
        WHERE state != "finished" AND identifier_id = ?
        ORDER BY #{sort} #{order};
      SQL

      @zenodo_copies = ZenodoCopy.find_by_sql([sql, params[:id]])
      @identifier = Identifier.find(params[:id])
    end

    def resubmit_job
      @zenodo_copy = ZenodoCopy.find(params[:id])
      copy_type = @zenodo_copy.copy_type.gsub('_publish', '')

      previous_unfinished = ZenodoCopy.where('id < ?', params[:id])
        .where(identifier_id: @zenodo_copy.identifier_id)
        .where('copy_type LIKE ?', "%#{copy_type}%")
        .where("state != 'finished'").count

      if previous_unfinished.positive?
        render plain: 'You may only resubmit a later item in a series after earlier items have successfully processed'
        return
      end

      if running_jobs(@zenodo_copy).count.positive?
        render plain: "This job is still in the delayed job runner so shouldn't be restarted right now"
        return
      end

      resend_job
    end

    def set_errored
      sql = <<~SQL
        #{BASIC_SQL}
        WHERE state != "finished";
      SQL
      @zenodo_copies = ZenodoCopy.find_by_sql(sql)

      @zenodo_copies.each do |zc|
        zc.update(state: 'error') unless running_jobs(zc).count.positive?
      end
    end

    private

    # pass in the zenodo copy
    def running_jobs(zc)
      if zc.copy_type.include?('software')
        Delayed::Job.where('handler LIKE ?', "%- #{zc.id}%").where(queue: 'zenodo_software')
      elsif zc.copy_type.include?('supp')
        Delayed::Job.where('handler LIKE ?', "%- #{zc}.id}%").where(queue: 'zenodo_supp')
      else
        Delayed::Job.where('handler LIKE ?', "%- #{zc.resource_id}%").where(queue: 'zenodo_copy')
      end
    end

    # uses @zenodo_copy
    def resend_job
      @zenodo_copy.update(state: 'enqueued')
      if @zenodo_copy.copy_type.include?('software')
        ZenodoSoftwareJob.perform_later(@zenodo_copy.id)
      elsif @zenodo_copy.copy_type.include?('supp')
        ZenodoSuppJob.perform_later(@zenodo_copy.id)
      else
        ZenodoCopyJob.perform_later(@zenodo_copy.resource_id)
      end
    end
  end
end
