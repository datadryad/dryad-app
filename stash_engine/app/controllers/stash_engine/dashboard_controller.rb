require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: %i[show migrate_data_mail migrate_data]
    before_action :require_terms_accepted, only: [:show]

    MAX_VALIDATION_TRIES = 5

    def show
      session[:show_migrate] = !current_user.migration_complete?
    end

    def accept_terms
      current_user.terms_accepted_at = Time.new
      current_user.save
      render 'stash_engine/dashboard/show'
    end

    def metadata_basics; end

    def preparing_to_submit; end

    def upload_basics; end

    def migrate_data_mail
      return unless validate_form_email
      email_code
      flash.now[:info] = 'An email with your code has been sent to your email address.'
      render 'migrate_data'
    end

    def migrate_data
      return unless validate_form_token_format && validate_form_token

      create_missing_email_address
      do_data_migration
      render 'migrate_successful'
    end

    def migration_complete
      current_user.migration_complete!
      respond_to do |format|
        format.js
      end
    end

    # def migrate_successful; end

    # an AJAX wait to allow in-progress items to complete before continuing.
    def ajax_wait
      respond_to do |format|
        format.js do
          sleep 0.1
          head :ok, content_type: 'application/javascript'
        end
      end
    end

    # methods below are private
    private

    def email_code
      current_user.update(old_dryad_email: params[:email])
      current_user.set_migration_token
      StashEngine::MigrationMailer.migration_email(email: current_user.old_dryad_email,
                                                   code: current_user.migration_token,
                                                   url: auth_migrate_code_url).deliver_now
    end

    def validate_form_email
      if params[:email].nil? || !params[:email][/^.+\@.+\..+$/]
        flash.now[:info] = 'Please fill in a correct email address' if params[:commit]
        render 'migrate_data'
        return false
      end
      true
    end

    def validate_form_token_format
      if params[:code].nil? || !params[:code][/^\d{6}$/]
        flash.now[:info] = 'Please enter your correct 6-digit code to migrate your data' if params[:commit] == 'Migrate data'
        return false
      end
      true
    end

    # rubocop:disable Metrics/AbcSize
    def validate_form_token
      token_user = User.find_by_migration_token(params[:code])

      if token_user.nil? || token_user.id != current_user.id
        current_user.increment!(:validation_tries)
        flash.now[:alert] = 'The code you entered is incorrect.'
        if current_user.validation_tries > MAX_VALIDATION_TRIES
          flash.now[:alert] = "You've had too many incorrect code validation attempts.  Please contact us to resolve this problem."
        end
        return false
      end
      true
    end
    # rubocop:enable Metrics/AbcSize

    def create_missing_email_address
      current_user.update(email: current_user.old_dryad_email) if current_user.email.blank? && !current_user.old_dryad_email.blank?
    end

    # it's not clear the full mechanics of this yet, yet it's likely to be close to these:
    # 1) find the old user record for the previous account
    # 2) update the resource.user_id (owner) for resources from the old user_id to the new user_id so this new user now owns them
    # 3) update any resource.current_editor_ids using the old user_id to the new user_id
    # 4) remove or disable the old user account after migration since their datasets have been moved to their new login
    def do_data_migration
      current_user.migration_complete!
    end

  end
end
