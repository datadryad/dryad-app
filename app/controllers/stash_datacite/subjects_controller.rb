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
      params[:subject]
        .split(/\s*[,()]\s*/)
        .map { |s| strip_subject(s) }
        .delete_if(&:blank?)
        .each { |s| ensure_subject(s) }
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

    def ensure_subject(subject_str)
      subject = Subject.non_fos.find_or_create_by(subject: subject_str)
      subjects = @resource.subjects
      return if subjects.include?(subject)

      subjects << subject
    end

    def set_subject
      return if params[:id] == 'new'

      @subject = Subject.find(params[:id])
      ajax_blocked unless @subject.resources.map(&:id).include?(resource.id)
    end

    def resource
      @resource ||= StashEngine::Resource.find(params[:resource_id])
    end

    def strip_subject(text)
      text.gsub(/^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$/, '')
    end
  end
end
