require_dependency "stash_datacite/application_controller"
require 'byebug'

module StashDatacite
  class FosSubjectsController < ApplicationController
    # before_action :set_fos_subject, only: [:show, :edit, :update, :destroy]
    # before_action :set_fos_subject, only: [:delete]
    before_action :ajax_require_modifiable, only: %i[update]

    # GET /fos_subjects
    def index
      @fos_subjects = FosSubject.all
    end

    # PATCH/PUT /fos_subjects/1
    # We are using this for both new/update, id is resource_id, fos_subjects is the subject
    def update

      if @fos_subject.update(fos_subject_params)
        redirect_to @fos_subject, notice: 'Fos subject was successfully updated.'
      else
        render :edit
      end
    end

    def resource
      @resource ||= StashEngine::Resource.find(params[:id])
    end
  end
end
