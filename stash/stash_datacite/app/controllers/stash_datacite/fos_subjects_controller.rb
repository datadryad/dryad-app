require_dependency "stash_datacite/application_controller"

module StashDatacite
  class FosSubjectsController < ApplicationController
    before_action :set_fos_subject, only: [:show, :edit, :update, :destroy]

    # GET /fos_subjects
    def index
      @fos_subjects = FosSubject.all
    end

    # GET /fos_subjects/1
    def show
    end

    # GET /fos_subjects/new
    def new
      @fos_subject = FosSubject.new
    end

    # GET /fos_subjects/1/edit
    def edit
    end

    # POST /fos_subjects
    def create
      @fos_subject = FosSubject.new(fos_subject_params)

      if @fos_subject.save
        redirect_to @fos_subject, notice: 'Fos subject was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /fos_subjects/1
    def update
      if @fos_subject.update(fos_subject_params)
        redirect_to @fos_subject, notice: 'Fos subject was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /fos_subjects/1
    def destroy
      @fos_subject.destroy
      redirect_to fos_subjects_url, notice: 'Fos subject was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_fos_subject
        @fos_subject = FosSubject.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def fos_subject_params
        params.fetch(:fos_subject, {})
      end
  end
end
