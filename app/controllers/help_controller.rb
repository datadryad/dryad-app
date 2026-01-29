class HelpController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController
  caches_page :topic

  rescue_from 'ActionView::MissingTemplate' do
    redirect_to help_path
  end

  def topic
    respond_to do |format|
      format.html do
        redirect_to '/help/guides/submission' and return if params[:folder] == 'submission_steps' && params[:page] == 'submission'
        redirect_to '/help/guides/publication' and return if params[:folder] == 'submission_steps' && params[:page] == 'publication'
        redirect_to '/help/guides/curation' and return if params[:folder] == 'submission_steps' && params[:page] == 'curation'

        render "help/#{params[:folder]}/#{params[:page]}"
      end
      format.pdf do
        redirect_to "/docs/#{params[:page]}.pdf"
      end
    end
  end
end
