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
      @author = StashEngine::Author.new(author_params)
      respond_to do |format|
        @affiliation = find_or_create_affiliation(params[:affiliation])
        @author.affiliation_id = @affiliation.id if @affiliation
        @author.save
        @author.reload
        format.js
      end
    end

    # PATCH/PUT /authors/1
    def update
      respond_to do |format|
        @author.update(author_params)
        @affiliation = find_or_create_affiliation(params[:affiliation])
        @author.affiliation_id = @affiliation.id if @affiliation
        @author.save
        @author.reload
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
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_middle_name, :author_email,
                                     :affiliation_id, :resource_id, :author_orcid)
    end

    def check_for_orcid(author)
      author.author_orcid ? true : false
    end

    def find_or_create_affiliation(affiliation_param)
      return nil unless affiliation_param && affiliation_param.present?
      affiliation_str = affiliation_param.to_s
      existing = Affiliation.where('long_name LIKE ? OR short_name LIKE ?', affiliation_str, affiliation_str).first
      return existing if existing
      Affiliation.create(long_name: affiliation_str)
    end
  end
end
