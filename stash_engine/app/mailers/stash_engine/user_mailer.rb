module StashEngine

  # Mails users about submissions
  class UserMailer < ApplicationMailer

    # Called from CurationActivity when the status is submitted, peer_review, published or embargoed
    def status_change(resource)
      return unless %w[submitted peer_review published embargoed].include?(resource.current_curation_status)
      @resource = resource
      mail(to: @resource.user.email, template_name: @resource.current_curation_status,
           subject: "#{rails_env} Dryad Submission \"#{@resource.title}\"")
    end

    # Called from the LandingController when an update happens
    def orcid_invitation(orcid_invite)
      # need to calculate url here because url helpers work erratically in the mailer template itself
      path = StashEngine::Engine.routes.url_helpers.show_path(orcid_invite.identifier.to_s, invitation: orcid_invite.secret)
      @url = orcid_invite.landing(path)
      @resource = orcid_invite.resource
      mail(to: orcid_invite.email,
           subject: "#{rails_env} Dryad Submission \"#{@resource.title}\"")
    end

    # Called from the StashEngine::Repository
    def submission_failed(resource, error)
      warn("Unable to report submission failure #{error}; nil resource") unless resource.present?
      return false unless resource.present?
      @resource = resource
      mail(to: @resource.user.email,
           bcc: @submission_error_emails,
           subject: "#{rails_env} Dryad Submission Failure \"#{@resource.title}\"")
    end

    # Called from the StashEngine::Repository
    def error_report(resource, error)
      warn("Unable to report update error #{error}; nil resource") unless resource.present?
      return unless resource.present?

      @resource = resource
      @backtrace = to_backtrace(error)

      to_address = address_list(APP_CONFIG['submission_error_email'])
      bcc_address = address_list(APP_CONFIG['submission_bc_emails'])
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env} Submitting dataset \"#{@title}\" (doi:#{@identifier_value}) failed")
    end

    private

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
