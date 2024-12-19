module StashDatacite
  class FosSubjectsController < ApplicationController
    before_action :ajax_require_modifiable, only: %i[update]

    # PATCH/PUT /fos_subjects/1
    # We are using this for both new/update, id is resource_id, fos_subjects is the subject
    def update
      respond_to do |format|
        format.json do
          # this removes the current associated fos subjects, but doesn't delete subject entries from subjects table
          resource.subjects.permissive_fos.each do |subj|
            ResourcesSubjects.where(resource_id: resource, subject_id: subj).destroy_all
          end
          resource.subjects << make_or_get_subject(params[:fos_subjects]) unless params[:fos_subjects].blank?
          render json: resource.subjects.permissive_fos
        end
      end
    end

    # GET /fos_subjects
    def index
      subjects = StashDatacite::Subject.fos.pluck(:subject).uniq.sort
      if params.key?(:select)
        selected = CGI.unescape(params[:select])
        render partial: 'stash_engine/shared/search_select', locals: {
          id: 'fos_subjects',
          label: 'Research domain',
          field_name: 'domain',
          options: subjects.map { |i| { value: i, label: i } }.to_json.html_safe,
          options_label: 'label',
          options_value: 'value',
          selected: { value: selected, label: selected }
        }
      else
        render json: subjects
      end
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
