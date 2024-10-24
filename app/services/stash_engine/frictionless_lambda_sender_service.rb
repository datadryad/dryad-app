module StashEngine
  class FrictionlessLambdaSenderService < BaseSenderService

    def call
      trigger_call('frictionless')
    end

    private

    def fail_message
      "Error invoking excelToCsv lambda for file: #{data_file.id}"
    end

    def callback_url
      Rails.application.routes.url_helpers.file_frictionless_report_url(data_file.id)
        .gsub('http://localhost:3000', 'https://v3-dev.datadryad.org')
        .gsub(/^http:/, 'https:')
    end
  end
end
