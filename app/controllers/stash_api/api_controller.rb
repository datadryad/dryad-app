# frozen_string_literal: true

module StashApi
  class ApiController < ApiApplicationController

    before_action :require_json_headers
    before_action :force_json_content_type
    before_action :doorkeeper_authorize!, only: :test
    before_action :require_api_user, only: :test

    REPORTS_DIR = 'reports'

    # get /
    # All this really does is return the basic HATEOAS output
    def index
      render json: output
    end

    # post /test
    # see if you can do a post request and connect with the key you've obtained
    def test
      render json: { message: "Welcome application owner #{@user.name}", user_id: @user.id }
    end

    def reports
      # Determine the list of available report_names
      all_reports = Dir.entries(REPORTS_DIR)
      all_reports.delete('..')
      all_reports.delete('.')
      report_names = all_reports.map { |r| r.sub(/.csv\z/, '') }
      report_names.uniq!

      # If a report_name is available, return the report,
      # with the current date on the filename
      if report_names.include?(params['report_name'])
        target_report = "#{params['report_name']}.csv"

        f = ::File.join(REPORTS_DIR, target_report)
        if ::File.exist?(f)
          d = Date.today
          result_filename = "#{params['report_name']}_#{d.strftime('%Y%m%d')}.csv"
          send_file f, filename: result_filename, type: 'text/plain'
          return
        else
          render json: { error: "Unable to render report file for #{target_report}" }, status: :internal_server_error
        end
      end

      # Else, report not_found
      render json: { error: "Could not find requested report #{params['report_name']}" }, status: :not_found
    end

    private

    def output
      {
        _links: {
          self: root_self,
          'stash:datasets': {
            href: datasets_path
          },
          curies: curies
        }
      }
    end

    def root_self
      {
        href: '/api/v2/'
      }
    end

    def curies
      [
        {
          name: 'stash',
          href: 'https://github.com/CDL-Dryad/stash/blob/main/stash_api/link-relations.md#{rel}', # rubocop:disable Lint/InterpolationCheck
          templated: 'true'
        }
      ]
    end

  end
end
