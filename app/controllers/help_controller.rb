class HelpController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController
  caches_page :topic

  def topic
    respond_to do |format|
      format.html do
        render "help/#{params[:folder]}/#{params[:page]}"
      end
      format.pdf do
        send_file(
          "#{File.join(Rails.root, 'app', 'views', 'help')}/#{params[:folder]}/#{params[:page]}.pdf",
          filename: params[:page], type: 'application/pdf', disposition: 'inline'
        )
      end
    end
  end
end
