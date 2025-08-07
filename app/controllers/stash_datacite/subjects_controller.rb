module StashDatacite
  class SubjectsController < ApplicationController

    before_action :set_subject, only: [:delete]
    before_action :ajax_require_modifiable, only: %i[create delete]

    # GET /subjects/new
    def new
      @subject = Subject.new
    end

    # POST /subjects
    def create
      Subjects::CreateService.new(resource, params[:subject], scope: :non_fos).call
      @subjects = resource.subjects.non_fos
      respond_to do |format|
        format.js
        format.json { render json: @subjects }
      end
    end

    # DELETE /subjects/1
    def delete
      # the following is the correct way to remove the join association between resource and subject
      # without deleting the other items entirely.  Deleting the subject will leave orphans in the join table.
      # If you have dependent destroy, it might destroy other associations to the same subject.
      ResourcesSubjects.where(resource_id: @resource, subject_id: @subject).destroy_all
      respond_to do |format|
        format.js
        format.json { render json: @subject }
      end
    end

    # GET /subjects
    def autocomplete
      if params[:term].blank?
        render json: nil
      else
        @subjects = Subject.order(:subject).non_fos.where('scheme_URI IS NOT NULL').where('subject LIKE ?', "%#{params[:term]}%").limit(40)
        render json: @subjects.map { |i| { id: i.id, name: i.subject } }
      end
    end

    # get subjects/landing(?params), for display of "keywords" on landing page
    def landing
      @resource = StashEngine::Resource.find(params[:resource_id])
      respond_to(&:js)
    end

    private

    def set_subject
      return if params[:id] == 'new'

      @subject = Subject.find(params[:id])
      ajax_blocked unless @subject.resources.map(&:id).include?(resource.id)
    end

    def resource
      @resource ||= StashEngine::Resource.find(params[:resource_id])
    end
  end
end
