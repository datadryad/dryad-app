module StashEngine

  # Mails users about submissions
  class UserMailer < ApplicationMailer

    # include ::StashDatacite::LandingMixin

    # Called from CurationActivity when the status is submitted, peer_review, published or embargoed
    def status_change(resource, status)
      return unless %w[submitted peer_review published embargoed].include?(status)
      user = resource.authors.first || resource.user
      return unless user.present? && user_email(user).present?
      @user_name = user_name(user)
      # @citation = generate_citation(resource) if status == 'published'
      assign_variables(resource)
      mail(to: user_email(user),
           bcc: @resource&.tenant&.campus_contacts,
           template_name: status,
           subject: "#{rails_env} Dryad Submission \"#{@resource.title}\"")
    end

    # Called from the LandingController when an update happens
    def orcid_invitation(orcid_invite)
      # need to calculate url here because url helpers work erratically in the mailer template itself
      path = StashEngine::Engine.routes.url_helpers.show_path(orcid_invite.identifier.to_s, invitation: orcid_invite.secret)
      @url = orcid_invite.landing(path)
      @user_name = "#{orcid_invite.first_name} #{orcid_invite.last_name}"
      assign_variables(orcid_invite.resource)
      mail(to: orcid_invite.email,
           subject: "#{rails_env} Dryad Submission \"#{@resource.title}\"")
    end

    # Called from the StashEngine::Repository
    def error_report(resource, error)
      warn("Unable to report update error #{error}; nil resource") unless resource.present?
      return unless resource.present?
      assign_variables(resource)
      @backtrace = to_backtrace(error)
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env} Submitting dataset \"#{@resource.title}\" (doi:#{@resource.identifier_value}) failed")
    end

    def dependency_offline(dependency)
      return unless dependency.present?
      @dependency = dependency
      @url = status_dashboard_url
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env} dependency offline: #{dependency.name}")
    end

    def helpdesk_notice(resource, message)
      warn('Unable to send helpdesk notice; nil resource') unless resource.present?
      return unless resource.present?
      assign_variables(resource)
      @message = message
      mail(to: @helpdesk_email,
           bcc: @bcc_emails,
           subject: "#{rails_env} Need assistance: \"#{@resource.title}\" (doi:#{@resource.identifier_value})")
    end

    private

    # rubocop:disable Style/NestedTernaryOperator
    def user_email(user)
      user.present? ? (user.respond_to?(:author_email) ? user.author_email : user.email) : nil
    end

    def user_name(user)
      user.present? ? (user.respond_to?(:author_standard_name) ? user.author_standard_name : user.name) : nil
    end
    # rubocop:enable Style/NestedTernaryOperator

    # defer to the StashDatacite::LandingMixin methods to create a citation
    #  def generate_citation(resource)
    #   return unless resource.is_a?(StashEngine::Resource)
    #   publisher = StashDatacite::Publisher.find_by(resource_id: resource.id).try(:publisher)
    #   resource_type = StashDatacite::ResourceType.find_by(resource_id: resource.id).try(:resource_type_general_friendly)
    #   citation(resource.authors, resource.title, resource_type, resource.version, resource.identifier, publisher, resource.publication_years)
    # end

    def assign_variables(resource)
      @resource = resource
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
      @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
      @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]
    end

    def rails_env
      return "[#{Rails.env}]" unless Rails.env == 'production'
      ''
    end

    # TODO: look at Rails standard ways to report/format backtrace
    def to_backtrace(e)
      backtrace = e.respond_to?(:backtrace) && e.backtrace ? e.backtrace.join("\n") : ''
      "#{e.class}: #{e}\n#{backtrace}"
    end

    def address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.flatten.reject(&:blank?).join(',')
    end

  end

end
