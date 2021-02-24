require_dependency 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: %i[show migrate_data_mail migrate_data]
    before_action :ensure_tenant, only: :show

    MAX_VALIDATION_TRIES = 5

    def show
      session[:show_migrate] = current_user && !current_user.migration_complete?
    end

    def metadata_basics; end

    def preparing_to_submit; end

    def upload_basics; end

    def react_basics; end

    def migrate_data_mail
      return unless validate_form_email

      email_code
      flash.now[:info] = 'An email with your code has been sent to your email address.'
      render 'migrate_data'
    end

    def migrate_data
      # this validates the user is also the same one as is logged in by the validation id
      # also the old_dryad_email gets filled when
      return unless validate_form_token_format && validate_form_token

      # make sure there is any old account to actually migrate
      return unless validate_old_dryad_email

      # this fills in the email if blank because ORCID doesn't always release email address
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

    # some people seem to get to the dashboard without having their tenant set.
    def ensure_tenant
      return unless current_user && current_user.tenant_id.blank?

      redirect_to choose_sso_path, alert: 'You must choose if you are associated with an institution before continuing'
    end

    def email_code
      current_user.update(old_dryad_email: params[:email])
      current_user.set_migration_token
      StashEngine::MigrationMailer.migration_email(current_user).deliver_now
    end

    def validate_form_email
      if params[:email].nil? || !params[:email][/^.+@.+\..+$/]
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

    def validate_old_dryad_email
      # this query is a bit weird since apparantly NULL oesn't compare with != as you might think
      @old_user = User.where(email: current_user.old_dryad_email).where('id != ? AND (migration_token IS NULL OR migration_token != ?)',
                                                                        current_user.id, StashEngine::User::NO_MIGRATE_STRING)
      unless @old_user.count.positive?
        flash.now[:alert] = "The email address you've validated does not match any that was used in the previous system.  " \
                             'Please contact us if you need assistance.'
        return false
      end
      @old_user = @old_user.first
      true
    end

    def create_missing_email_address
      current_user.update(email: current_user.old_dryad_email) if current_user.email.blank? && !current_user.old_dryad_email.blank?
    end

    def do_data_migration
      # we want to merge this current user account into the old user account and then switch the current user to be the old user account
      # variables are @current_user, session[:user_id] and @old_user for doing this operation

      old_current_user = current_user

      @old_user.merge_user!(other_user: current_user)

      # after done, switch around the users to use the one that previously existed and is being migrated to
      @current_user = @old_user
      session[:user_id] = @old_user.id

      # make the newer user inaccessible from the database (rather than deleting for now in case anything goes awry, we can purge later)
      old_current_user.update(orcid: "#{old_current_user.orcid}-migrated", migration_token: StashEngine::User::NO_MIGRATE_STRING)
      old_current_user.update(email: "#{old_current_user.email}.migrated") unless old_current_user.email.blank?
    end

  end
end
