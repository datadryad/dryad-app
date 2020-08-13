require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class FosSubjectsController < ApplicationController
    before_action :ajax_require_modifiable, only: %i[update]

    # PATCH/PUT /fos_subjects/1
    # We are using this for both new/update, id is resource_id, fos_subjects is the subject
    def update
      # this removes the current associated fos subjects, but doesn't delete subject entries from subjects table
      resource.subjects.permissive_fos.each { |subj| resource.subjects.delete(subj) }
      resource.subjects << make_or_get_subject(params[:fos_subjects]) unless params[:fos_subjects].blank?
    end

    def resource
      @resource ||= StashEngine::Resource.find(params[:id])
    end

    private

    def make_or_get_subject(subj)
      existing_subj = StashDatacite::Subject.permissive_fos.where(subject: subj).first
      return existing_subj unless existing_subj.blank?

      StashDatacite::Subject.create(subject: subj, subject_scheme: 'bad_fos')
    end
  end
end
