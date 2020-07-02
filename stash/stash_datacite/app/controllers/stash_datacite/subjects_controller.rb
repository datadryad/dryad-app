require_dependency 'stash_datacite/application_controller'

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
        .split(/\s*,\s*/)
        .delete_if(&:blank?)
        .each { |s| ensure_subject(s) }
      @subjects = resource.subjects
      respond_to { |format| format.js }
    end

    # DELETE /subjects/1
    def delete
      @subjects = resource.subjects
      resource.subjects.delete(@subject)
      respond_to do |format|
        format.js
      end
    end

    # GET /subjects
    def autocomplete
      if params[:term].blank?
        render json: nil
      else
        @subjects = Subject.order(:subject).where('subject LIKE ?', "%#{params[:term]}%")
        render json: @subjects.map(&:subject)
      end
    end

    # get subjects/landing(?params), for display of "keywords" on landing page
    def landing
      @resource = StashEngine::Resource.find(params[:resource_id])
      respond_to { |format| format.js }
    end

    private

    def ensure_subject(subject_str)
      subject = find_or_create_subject(subject_str)
      subjects = @resource.subjects
      return if subjects.exists?(subject)

      subjects << subject
    end

    def find_or_create_subject(subject)
      existing = Subject.where('subject LIKE ?', subject).first
      return existing if existing

      Subject.create(subject: subject)
    end

    def set_subject
      return if params[:id] == 'new'

      @subject = Subject.find(params[:id])
      return ajax_blocked unless @subject.resources.map(&:id).include?(resource.id)
    end

    def resource
      @resource ||= StashEngine::Resource.find(params[:resource_id])
    end
  end
end
