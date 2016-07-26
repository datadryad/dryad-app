require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class SubjectsController < ApplicationController
    # GET /subjects/new
    def new
      @subject = Subject.new
    end

    # POST /subjects
    def create
      @resource = StashEngine::Resource.find(params[:resource_id])
      subjects_array = subject_params[:subject].split(/\s*,\s*/).delete_if {|i| i.blank? }
      subjects_array.each do |sub|
        Subject.create(subject: sub) unless Subject.where('subject LIKE ?', sub).exists?
        @subject = Subject.where('subject LIKE ?', sub).first
        unless @resource.subjects.exists?(@subject)
          @resource.subjects << @subject
        end
      end
      @subjects = @resource.subjects
      respond_to do |format|
        format.js
      end
    end

    # DELETE /subjects/1
    def delete
      @subject = Subject.find(params[:id])
      @resource = StashEngine::Resource.find(params[:resource_id])
      @subjects = @resource.subjects
      @resource.subjects.delete(@subject)
      respond_to do |format|
        format.js
      end
    end

    # GET /subjects
    def autocomplete
      @subjects = Subject.order(:subject).where('subject LIKE ?', "%#{params[:term]}%") unless params[:term].blank?
      render json: @subjects.map(&:subject)
    end

    # get subjects/landing(?params), for display of "keywords" on landing page
    def landing
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_subject
      @subject = Subject.find(subject_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def subject_params
      params
    end
  end
end
