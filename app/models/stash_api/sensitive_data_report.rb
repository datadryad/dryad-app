# frozen_string_literal: true

require_relative 'presenter'
module StashApi
  class SensitiveDataReport
    include Presenter

    def initialize(file_obj:, result_obj:)
      @se_data_file = file_obj
      @resource = @se_data_file.resource
      @se_report = result_obj
    end

    def metadata
      { _links: links }.merge(report: @se_report.report,
                              createdAt: @se_report.created_at,
                              updatedAt: @se_report.updated_at,
                              status: @se_report.status).recursive_compact
    end

    def links
      basic_links.compact.merge(stash_curie)
    end

    def parent_version
      @version ||= Version.new(resource_id: @se_data_file.resource_id)
    end

    private

    def basic_links
      {
        self: { href: api_url_helper.file_sensitive_data_report_path(@se_data_file.id) },
        'stash:dataset': { href: parent_version.parent_dataset.self_path },
        'stash:version': { href: parent_version.self_path },
        'stash:files': { href: parent_version.files_path }
      }
    end
  end
end
