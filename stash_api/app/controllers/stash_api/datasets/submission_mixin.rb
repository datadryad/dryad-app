module SubmissionMixin

  private

  def check_patch_prerequisites
    ensure_in_progress { yield }
    begin
      @json = JSON.parse(request.raw_post)
    rescue JSON::ParserError
      return_error(messages: 'You must send a json patch request with a valid JSON operation to publish this dataset', status: 400) { yield }
    end
    return if @json.length.positive? && @json.include?('op' => 'replace', 'path' => '/versionStatus', 'value' => 'submitted')
    return_error(messages: "You must issue a json operation of 'replace', path: '/versionStatus', value: 'submitted' to publish.",
                 status: 400) { yield }
  end

  def ensure_in_progress
    return if @stash_identifier.in_progress?
    return_error(messages: 'You must have an in_progress version to perform this operation', status: 400) { yield }
  end

  def check_dataset_completions
    errors = errors_for_completions
    if @resource.new_size > @resource.tenant.max_total_version_size && @resource.size > @resource.tenant.max_submission_size
      errors.push('The files for this dataset are larger than the allowed version or total object size')
    end
    if @resource.identifier&.processing?
      errors.push('Your previous version is still being processed, please wait until it completes before submitting again')
    end
    return unless errors.length.positive?
    return_error(messages: errors, status: 403) { yield }
  end

  def errors_for_completions
    completions = StashDatacite::Resource::Completions.new(@resource)
    if @resource.loosen_validation && @user.superuser?
      completions.relaxed_warnings
    else
      completions.all_warnings
    end
  end

  def pre_submission_updates
    StashDatacite::DataciteDate.set_date_available(resource_id: @resource.id)
    StashEngine::EditHistory.create(resource_id: @resource.id, user_comment: 'submitted from API')
  end

end
