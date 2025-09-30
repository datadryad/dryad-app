module StashEngine
  class FileUploadService
    attr_reader :resource, :file
    def initialize(resource:, file_params:, file_model: StashEngine::DataFile)
      @resource = resource
      @file_model = file_model
      file_params[:file_state] = 'created'
      file_params[:upload_updated_at] = Time.new
      file_params[:resource_id] = @resource.id
      @file = @file_model.new(file_params)
    end

    def save
      @file.save
      trigger_checks
      @file
    end

    private

    def trigger_checks
      trigger_frictionless if @resource.data_files.where(id: @file.id).tabular_files.present?
      trigger_sd_scan if @resource.data_files.where(id: @file.id).scannable_files.present?
    end

    def trigger_frictionless
      return unless @file.frictionless_report.blank?

      @file.set_checking_status
      result = StashEngine::FrictionlessLambdaSenderService.new(@file).call
      @file.frictionless_report.update(status: 'error', report: result[:msg]) if result[:triggered] == false
    end

    def trigger_sd_scan
      return unless @file.sensitive_data_report.blank?

      @file.set_checking_status(SensitiveDataReport)
      StashEngine::SensitiveDataLambdaSenderService.new(@file).call
    end

  end
end
