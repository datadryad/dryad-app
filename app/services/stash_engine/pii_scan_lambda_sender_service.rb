module StashEngine
  class PiiScanLambdaSenderService < BaseSenderService

    def call
      trigger_call('excelToCsv')
    end

    private

    def fail_message
      "Error invoking PII scan for file: #{data_file.id}"
    end

    def callback_url
      Rails.application.routes.url_helpers.file_pii_scan_report_url(data_file.id)
        .gsub('http://localhost:3000', 'https://v3-dev.datadryad.org')
        .gsub(/^http:/, 'https:')
    end
  end
end
