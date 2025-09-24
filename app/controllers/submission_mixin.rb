module SubmissionMixin

  private

  def check_patch_prerequisites
    begin
      @json = JSON.parse(request.raw_post)
      @json = [@json] if @json.is_a?(Hash)
    rescue JSON::ParserError
      return_error(messages: 'You must send a JSON Patch request with a valid JSON operation.', status: 400) { yield }
    end

    return if @json.length == 1

    return_error(messages: 'The Dryad API only accepts a JSON Patch request with a single statement.',
                 status: 400) { yield }
  end

  def ensure_in_progress
    return if @stash_identifier.in_progress?

    return_error(messages: 'You must have an in_progress version to perform this operation', status: 400) { yield }
  end

  def check_dataset_completions
    validation_service = StashDatacite::Resource::DatasetValidations.new(resource: @resource, user: @user)
    error = validation_service.errors
    error ||= validation_service.check_payment

    if @resource.identifier&.processing?
      error = 'Your previous version is still being processed, please wait until it completes before submitting again'
    end
    return unless error

    return_error(messages: error, status: 403) { yield }
  end

  def pre_submission_updates
    @resource.update(accepted_agreement: true)
    StashEngine::EditHistory.create(resource_id: @resource.id, user_comment: 'submitted from API')
  end
end
