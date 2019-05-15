require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AuthorsController < ApplicationController
    before_action :set_author, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete]

    respond_to :json

    # GET /authors/new
    def new
      @author = StashEngine::Author.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /authors
    def create
      respond_to do |format|
        @author = StashEngine::Author.create(process_affiliation)
        @author.reload
        format.js
      end
    end

    # PATCH/PUT /authors/1
    def update
      respond_to do |format|
        @author.update(process_affiliation)
        format.js { render template: 'stash_datacite/shared/update.js.erb' }
      end
    end

    # DELETE /authors/1
    def delete
      unless params[:id] == 'new'
        @resource = StashEngine::Resource.find(@author.resource_id)
        @if_orcid = check_for_orcid(@author)
        @author.destroy
      end
      respond_to do |format|
        format.js
      end
    end

    private

    def resource
      @resource ||= (params[:author] ? StashEngine::Resource.find(author_params[:resource_id]) : @author.resource)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_author
      return if params[:id] == 'new'
      @author = StashEngine::Author.find((params[:author] ? author_params[:id] : params[:id]))
      return ajax_blocked unless resource.id == @author.resource_id # don't let people play games with changing author ids
    end

    # Only allow a trusted parameter "white list" through.
    def author_params
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_middle_name,
                                     :author_email, :resource_id, :author_orcid,
                                     affiliation: %i[id ror_id long_name])
    end

    def check_for_orcid(author)
      author.author_orcid ? true : false
    end

    def process_affiliation
      args = author_params
      affil = StashDatacite::Affiliation.from_long_name(args['affiliation']['long_name'])
      args['affiliation']['id'] = affil.id unless affil.blank?

      # This would not be necessary if the relationship between author and affiliations
      # was updated to a one-one and an accepts_nested_attributes_for definition
      @author.affiliation = affil
      @author.save

      args
    end

  end
end
