module StashEngine
  class ZenodoQueueController < ApplicationController

    helper SortableTableHelper
    before_action :require_user_login

    ALLOWED_SORT = %w[id identifier_id resource_id state updated_at copy_type size].freeze
    ALLOWED_ORDER = %w[asc desc].freeze

    BASIC_SQL = <<~SQL.freeze
      SELECT id, state, deposition_id, identifier_id, resource_id, created_at, updated_at, retries, copy_type, software_doi, conceptrecid, CASE
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
      authorize %i[stash_engine zenodo_copy]
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
      authorize %i[stash_engine zenodo_copy]
      @zenodo_copy = ZenodoCopy.find(params[:id])

      @delayed_jobs = running_jobs(@zenodo_copy)
    end

    def identifier_details
      authorize %i[stash_engine zenodo_copy]
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
      authorize %i[stash_engine zenodo_copy]
      @zenodo_copy = ZenodoCopy.find(params[:id])
      respond_to do |format|
        format.js do
          copy_type = @zenodo_copy.copy_type.gsub('_publish', '')

          previous_unfinished = ZenodoCopy.where('id < ?', params[:id])
                                          .where(identifier_id: @zenodo_copy.identifier_id)
                                          .where('copy_type LIKE ?', "%#{copy_type}%")
                                          .where("state != 'finished'").count

          @sub_status = ''
          @sub_status = 'prerequisite' if previous_unfinished.positive?

          @sub_status = 'in runner' if running_jobs(@zenodo_copy).count.positive?

          resend_job if @sub_status.blank?
        end
      end
    end

    def set_errored
      authorize %i[stash_engine zenodo_copy]
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
