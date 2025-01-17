module StashEngine
  class SensitiveDataLambdaSenderService < BaseSenderService

    def call
      trigger_call('sensitive_data_scan')
    end

    private

    def fail_message
      "Error invoking sensitive data scan for file: #{data_file.id}"
    end

    def callback_url
      Rails.application.routes.url_helpers.file_sensitive_data_report_url(data_file.id)
        .gsub('http://localhost:3000', 'https://v3-dev.datadryad.org')
        .gsub(/^http:/, 'https:')
    end
  end
end
