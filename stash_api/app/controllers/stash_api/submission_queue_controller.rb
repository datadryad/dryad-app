require_dependency 'stash_api/application_controller'
require_dependency 'stash_api/datasets_controller'

module StashApi
  class SubmissionQueueController < ApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_curator # curators and superusers are conflated

  end
end