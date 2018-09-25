require_dependency 'stash_api/application_controller'

module StashApi
  class UsersController < ApplicationController

    before_action :doorkeeper_authorize!, only: %i[show index]
    before_action :require_api_user, only: %i[show index]
    before_action :require_superuser, only: %i[show index]

    # Things we want to expose
    # id, first_name, last_name, email, created_at, tenant_id, role, orcid, old_dryad_email, eperson_id
    DB_FIELDS = %w[id first_name last_name email tenant_id role orcid old_dryad_email eperson_id created_at].freeze
    DISPLAY_FIELDS = %w[id firstName lastName email tenantId role orcid oldDryadEmail ePersonId createdAt].freeze
    DB_TO_DISPLAY = Hash[DB_FIELDS.zip(DISPLAY_FIELDS)]
    DISPLAY_TO_DB = Hash[DISPLAY_FIELDS.zip(DB_FIELDS)]

    # get /users/<id>
    def show
      user = StashEngine::User.find(params[:id])
      user = User.new(user_id: user)
      respond_to do |format|
        format.json { render json: user.metadata }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /users
    def index
      query_hash = params.slice(*DISPLAY_FIELDS).transform_keys(&DISPLAY_TO_DB) # limits to display fields and transforms to DB fields
      filtered_users = StashEngine::User.where(query_hash.to_hash) # this was ActionController::Parameters
      out = paged_users(filtered_users)
      respond_to do |format|
        format.json { render json: out }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    private

    def paged_users(results)
      all_count = results.count
      results = results.limit(page_size).offset(page_size * (page - 1))
      results = results.map { |user| User.new(user_id: user.id).metadata }
      paging_hash_results(all_count, results)
    end

    def paging_hash_results(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:users' => results }
      }
    end
  end
end
