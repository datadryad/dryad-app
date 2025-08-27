module StashEngine
  class EditCodesController < ApplicationController

    # rubocop:disable Metrics/AbcSize
    def accept_invite
      if current_user
        @edit_code = StashEngine::EditCode.where(edit_code: params[:edit_code])&.last
        if @edit_code.nil? || @edit_code.applied
          redirect_to stash_url_helpers.dashboard_path, alert: 'This invitation has already been accepted.'
          return
        end

        @resource = @edit_code.author.resource
        if @resource.nil?
          redirect_to stash_url_helpers.root_path, alert: 'The dataset you are looking for no longer exists.'
          return
        end

        if @edit_code.role == 'submitter'
          @resource.submitter = current_user.id
        else
          @resource.roles.find_or_create_by(user_id: current_user.id).update(role: params[:role])
        end
        @edit_code.author.update(author_orcid: current_user.orcid, author_email: current_user.email)
        @edit_code.update(applied: true)
        redirect_to stash_url_helpers.dashboard_path, notice: "You may now collaborate on #{@resource.title.html_safe}"
      else
        flash[:alert] = 'You must log in to accept this invitation.'
        session[:target_page] = request.fullpath
        redirect_to stash_url_helpers.choose_login_path and return
      end
    end
    # rubocop:enable Metrics/AbcSize

  end
end
