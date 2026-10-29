require 'net/http'
require 'json'
require 'stash/salesforce'

module StashEngine
  module AdminDatasetsHelper

    def sponsor_select
      StashEngine::JournalOrganization.all.map { |item| [item.name, item.id] }.sort_by { |i| i[0].downcase }
    end

    def pub_state_select
      StashEngine::Identifier.pub_states.keys.map do |state|
        [state.upcase_first, state]
      end
    end

    def status_select(statuses = [])
      statuses = StashEngine::CurationActivity.statuses.keys if statuses.empty?
      statuses.map do |status|
        [StashEngine::CurationActivity.readable_status(status), status]
      end
    end

    def filter_status_select(current_status, pub_state)
      statuses = StashEngine::CurationActivity.allowed_states(current_status, pub_state).sort

      statuses.delete(current_status) unless current_status == 'retracted'
      # because we don't show the current state as an option, it is implied by leaving state blank

      # makes select list
      status_select(statuses) unless statuses.empty?
    end

    def editor_select
      curators = StashEngine::User.all_curators
      curators.sort { |a, b| a.last_name.to_s <=> b.last_name.to_s }.map do |c|
        [c.name_last_first, c.id]
      end
    end

    def flag_select
      flags = StashEngine::Flag.flags.map { |k, _v| [k.humanize, k] }
      flags + [['Flagged user', 'user'], ['Flagged institution', 'tenant'], ['Flagged journal', 'journal']]
    end

    def display_payment(identifier)
      return 'Unknown' if identifier.dpc_payment.nil?

      if identifier.waiver?
        return 'Waiver' if StashEngine::Waiver.basis_ids.include?(identifier.dpc_payment.payment_id)

        return identifier.dpc_payment.payment_id.humanize
      end

      str = identifier.user_paid_dpc? ? 'Unsponsored: ' : 'Sponsored: '
      str += identifier.dpc_payment.link
      str.html_safe
    end

    def display_payment_err(resource)
      return unless resource.submitted?
      return unless resource.identifier.dpc_payment.nil?
      return if resource.identifier.old_payment_system?

      "<span class=\"child-details error-text\" id=\"payment_desc_err\">
          <i class=\"fas fa-triangle-exclamation\" aria-hidden=\"true\"></i> Action required: payment or sponsorship needed
        </span>".html_safe
    end

    def display_publications(resource)
      str = resource.resource_publication&.publication_name&.present? ? "#{resource.resource_publication&.publication_name}, " : ''
      str += resource.resource_publication&.manuscript_number&.presence || ''
      if resource.manuscript.present?
        status = (resource.manuscript.accepted? && 'accepted') || (resource.manuscript.rejected? && 'rejected') || 'submitted'
        str += "<span id=\"status-label\" class=\"#{status}\">#{status}</span>"
      elsif resource.identifier.has_api_acceptance?
        str += '<span id="status-label" class="accepted">accepted</span>'
      end
      str += '<span id="doi-label" class="accepted">published</span>' if resource.identifier.publication_article_doi.present?
      unless resource.related_identifiers.empty?
        str += "<br/>#{resource.related_identifiers.size} related work#{'s' if resource.related_identifiers.size > 1}"
      end
      str.html_safe
    end

    def format_external_references(instring, text: nil)
      return '' unless instring.present?

      # Stripe invoice references
      if instring.start_with?('in_', 'pi_') && !instring.start_with?('in_progress')
        str = instring.start_with?('in_') ? 'invoice' : 'payment'
        text ||= str
        return render inline:
          link_to(text, "#{ResourcePayment::STRIPE_LINK}/#{str.pluralize}/#{instring}", target: :_blank)
      end

      # Turn salesforce references into hyperlinks
      matchdata = instring.match(/(.*)SF ?#? ?(\d+)(.*)/)
      return instring unless matchdata

      sf_link = Stash::Salesforce.case_view_url(case_num: matchdata[2])
      return instring unless sf_link.present?

      render inline: matchdata[1] + link_to("SF #{matchdata[2]}", sf_link, target: :_blank) + matchdata[3]
    end

    def aar_resource(identifier)
      return identifier.latest_resource.id if %w[curation action_required].include?(identifier.latest_resource.current_curation_status)

      aar = identifier.last_status_activity('action_required')
      return aar.resource.id if aar.present? && aar.resource.current_curation_status == 'action_required'

      nil
    end

    def salesforce_links(doi)
      Stash::Salesforce.find_cases_by_doi(doi)
    end

    def display_issues(issues)
      issues&.map do |issue|
        json = Integrations::Github.new.query_issue(issue)
        next unless json['title'].present?

        {
          url: json['html_url'],
          title: json['title'],
          assignee: json.dig('assignee', 'login'),
          status: json['closed_at'].present? ? 'Closed' : 'Open'
        }
      end&.reject(&:blank?)
    end
  end
end
