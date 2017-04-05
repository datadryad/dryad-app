require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class AuthorsController < ApplicationController
    before_action :set_author, only: [:update]

    respond_to :json

    # GET /authors/new
    def new
      @author = Author.new(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    # POST /authors
    def create
      duplicate_affiliation = Affiliation.where('long_name LIKE ? OR short_name LIKE ?',
                                                params[:affiliation].to_s, params[:affiliation].to_s).first
      @author = Author.new(author_params)
      respond_to do |format|
        @author.save
        @author.reload
        unless duplicate_affiliation.present?
          if params[:affiliation].present?
            @affiliation = Affiliation.create(long_name: params[:affiliation])
            @author.affiliation_id = @affiliation.id
            @author.save
          else
            ''
          end
        end
        format.js
      end
    end

    # PATCH/PUT /authors/1
    def update
      duplicate_affiliation = Affiliation.where('long_name LIKE ? OR short_name LIKE ?',
                                                params[:affiliation].to_s, params[:affiliation].to_s).first
      respond_to do |format|
        unless duplicate_affiliation.present?
          @author.update(author_params)
          @author.reload
          if params[:affiliation].present?
            @affiliation = Affiliation.create(long_name: params[:affiliation])
            @author.affiliation = @affiliation
            @author.save
          else
            ''
          end
        else
          @author.update(author_params)
          @author.affiliation = duplicate_affiliation
          @author.save
        end
        format.js { render template: 'stash_datacite/shared/update.js.erb' }
      end
    end

    # DELETE /authors/1
    def delete
      unless params[:id] == 'new'
        @author = Author.find(params[:id])
        @resource = StashDatacite.resource_class.find(@author.resource_id)
        @if_orcid = check_for_orcid_id(@author)
        @author.destroy
      end
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_author
      @author = Author.find(author_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def author_params
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_middle_name,
                                      :name_identifier_id, :affiliation_id, :resource_id, :orcid_id)
    end

    def check_for_orcid_id(author)
      author.orcid_id ? true : false
    end
  end
end
