module StashEngine
  class ExcelToCsvLambdaSenderService < BaseSenderService

    def call
      # Don't create multiple entries for all the processing steps, just overwrite this one (will save last step).
      # We can move to a more full log of every step in the future if we need it.
      @pr = ProcessorResult.where(resource_id: resource_id, parent_id: id)&.first ||
        ProcessorResult.create(resource: resource, processing_type: 'excel_to_csv', parent_id: id, completion_state: 'not_started')

      trigger_call('excelToCsv')
    end

    private

    def payload
      super.merge(
        {
          filename: upload_file_name,
          doi: resource.identifier.to_s,
          processor_obj: @pr.as_json
        }
      )
    end

    def fail_message
      "Error invoking lambda for file: #{data_file.id}"
    end

    def callback_url
      Rails.application.routes.url_helpers.processor_result_url(@pr.id)
        .gsub('http://localhost:3000', 'https://v3-dev.datadryad.org')
        .gsub(/^http:/, 'https:')
    end
  end
end
