require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class SubjectsController < ApplicationController

    # GET /subjects/new
    def new
      @subject = Subject.new
    end

    # POST /subjects
    def create
      @resource =  StashEngine::Resource.find(params[:resource_id])
      subjects_array = subject_params[:subject].split(/[ ,]+/)
      subjects_array.each do |sub|
        unless Subject.where("subject LIKE ?", sub).exists?
          @resource.subjects << Subject.create(subject: sub)
        end
      end
      @subjects = @resource.subjects.pluck(:subject).join(", ")
      render template: 'stash_datacite/shared/update.js.erb'
    end

    # DELETE /subjects/1
    def destroy
      @subject.destroy
      redirect_to subjects_url, notice: 'Subject was successfully destroyed.'
    end

    # GET /subjects
    def autocomplete
      @subjects = Subject.order(:subject).where("subject LIKE ?", "%#{params[:term]}%") unless params[:term].blank?
      render json: @subjects.map(&:subject)
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
