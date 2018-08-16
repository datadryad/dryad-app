require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: [:show]
    after_filter -> { flash.discard }, only: [:migrate_data_mail]

    def show
      session[:show_migrate] = !current_user.migration_complete?
    end

    def metadata_basics; end

    def preparing_to_submit; end

    def upload_basics; end

    def migrate_data_mail
      if params[:email].nil? || !params[:email][/^.+\@.+\..+$/]
        flash[:info] = 'Please fill in a correct email address' if params[:commit]
        render 'migrate_data'
        return
      end
      current_user.old_dryad_email = params[:email]
      current_user.set_migration_token
      current_user.save
      StashEngine::MigrationMailer.migration_email(email: current_user.old_dryad_email,
                                                   code: current_user.migration_token,
                                                   url: auth_migrate_code_url).deliver_now
      redirect_to auth_migrate_code_path(email: params[:email])
    end

    def migrate_data
      if params[:email] && (params[:code].nil? || !params[:code][/^\d{6}$/])
        flash[:info] = 'Please enter your 6-digit code to migrate your data'
        return
      end
      if User.find_by_migration_token(params[:code]).nil? || User.find_by_migration_token(params[:code]).id != current_user.id
        flash[:error] = 'Incorrect code.'
        redirect_to auth_migrate_mail_path
        return
      end
      current_user.migration_complete
      render 'stash_engine/dashboard/migrate_successful'
    end

    def migrate_successful; end

    def migrate_no
      current_user.migration_complete
      redirect_to dashboard_path
    end

    # an AJAX wait to allow in-progress items to complete before continuing.
    def ajax_wait
      respond_to do |format|
        format.js do
          sleep 0.1
          head :ok, content_type: 'application/javascript'
        end
      end
    end
  end
end
