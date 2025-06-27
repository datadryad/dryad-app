module StashEngine
  class ExcelToCsvLambdaSenderService < BaseSenderService

    def call
      # Don't create multiple entries for all the processing steps, just overwrite this one (will save last step).
      # We can move to a more full log of every step in the future if we need it.
      @pr = ProcessorResult.where(resource_id: resource.id, parent_id: data_file.id)&.first ||
        ProcessorResult.create(resource: resource, processing_type: 'excel_to_csv', parent_id: data_file.id, completion_state: 'not_started')

      trigger_call('excelToCsv')
    end

    private

    def payload
      res = JSON.parse(super)
      JSON.generate(
        res.merge({
                    filename: data_file.download_filename,
                    doi: resource.identifier.to_s,
                    processor_obj: @pr.as_json
                  })
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
