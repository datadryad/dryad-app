require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login
    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
    end

    def metadata_callback
      auth_hash = request.env['omniauth.auth']
      params = request.env['omniauth.params']
      current_user = StashEngine::User.find(params['current_user_id'])
      path = request.env['omniauth.origin']
      creator = metadata_engine::Creator.new(resource_id: params['resource_id'],
                                             creator_first_name: auth_hash.info.first_name,
                                             creator_last_name: auth_hash.info.last_name,
                                             orcid_id: auth_hash.uid)
      creator.save
      if creator.creator_first_name.downcase == current_user.first_name.downcase &&
         creator.creator_last_name.downcase == current_user.last_name.downcase
        current_user.orcid = true
        current_user.save
      end
      redirect_to path
    end
  end
end
