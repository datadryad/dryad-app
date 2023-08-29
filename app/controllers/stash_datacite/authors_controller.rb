module StashDatacite
  class AuthorsController < ApplicationController
    before_action :check_reorder_valid, only: %i[reorder]
    before_action :set_author, only: %i[update delete]
    before_action :ajax_require_modifiable, only: %i[update create delete reorder]

    respond_to :json

    # GET /authors/new
    def new
      @author = StashEngine::Author.new(resource_id: params[:resource_id])
      respond_to(&:js)
    end

    # POST /authors
    def create
      respond_to do |format|
        @author = StashEngine::Author.create(author_params)
        process_affiliation unless params[:affiliation].nil?
        @author.reload
        format.js
        format.json { render json: @author.as_json.merge(affiliation: @author.affiliation.as_json) }
      end
    end

    # PATCH/PUT /authors/1
    def update
      respond_to do |format|
        @author.update(author_params)
        process_affiliation
        format.js { render template: 'stash_datacite/shared/update.js.erb' }
        format.json { render json: @author.as_json.merge(affiliation: @author.affiliation.as_json) }
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
        format.json { render json: @author }
      end
    end

    # takes a list of author ids and their new orders like [{id: 3323, order: 0},{id:3324, order: 1}] etc
    def reorder
      respond_to do |format|
        format.json do
          js = params[:author].to_h.to_a.map { |i| { id: i[0], author_order: i[1] } }
          # js = params['_json'].map { |i| { id: i[:id], author_order: i[:order] } } # convert weird params objs to hashes
          grouped_authors = js.index_by { |author| author[:id] }
          resp = StashEngine::Author.update(grouped_authors.keys, grouped_authors.values)
          render json: resp, status: :ok
        end
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
      ajax_blocked unless resource.id == @author.resource_id # don't let people play games with changing author ids
    end

    # Only allow a trusted parameter "white list" through.
    def author_params
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_middle_name,
                                     :author_email, :resource_id, :author_orcid, :author_order,
                                     affiliation: %i[id ror_id long_name])
    end

    def check_for_orcid(author)
      author&.author_orcid ? true : false
    end

    # find correct affiliation based on long_name and ror_id and set it, create one if needed.
    def process_affiliation
      return nil unless @author.present?

      args = author_params
      if args['affiliation']['long_name'].blank?
        @author.affiliations.destroy_all
        return
      end

      # find a matching pre-existing affiliation
      affil = nil
      name = args['affiliation']['long_name']
      ror_val = args['affiliation']['ror_id']
      if ror_val.present?
        # - find by ror_id if avaialable
        affil = StashDatacite::Affiliation.where(ror_id: ror_val).first
      else
        # - find by name otherwise
        affil = StashDatacite::Affiliation.where(long_name: name).first
        affil = StashDatacite::Affiliation.where(long_name: "#{name}*").first unless affil.present?
      end

      # if no matching affils found, make a new affil
      if affil.blank?
        affil = if ror_val.present?
                  StashDatacite::Affiliation.create(long_name: name, ror_id: ror_val)
                else
                  StashDatacite::Affiliation.create(long_name: "#{name}*", ror_id: nil)
                end
      end

      @author.affiliation = affil
      @author.save
    end

    def check_reorder_valid
      params.require(:author).permit!
      @authors = StashEngine::Author.where(id: params[:author].keys)

      # you can only order things belonging to one resource
      render json: { error: 'bad request' }, status: :bad_request unless @authors.map(&:resource_id)&.uniq&.length == 1

      @resource = StashEngine::Resource.find(@authors.first.resource_id) # set resource to check permission to modify
    end

  end
end
