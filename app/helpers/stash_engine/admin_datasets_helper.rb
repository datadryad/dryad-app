require 'stash/salesforce'

module StashEngine
  module AdminDatasetsHelper

    def sponsor_select
      StashEngine::JournalOrganization.all.map { |item| [item.name, item.id] }.sort_by { |i| i[0].downcase }
    end

    def status_select(statuses = [])
      statuses = StashEngine::CurationActivity.statuses.keys if statuses.empty?
      statuses.map do |status|
        [StashEngine::CurationActivity.readable_status(status), status]
      end
    end

    def filter_status_select(current_status)
      statuses = StashEngine::CurationActivity.allowed_states(current_status, current_user).sort

      statuses.delete(current_status) # because we don't show the current state as an option, it is implied by leaving state blank

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

    def display_publications(resource)
      str = resource.resource_publication&.publication_name&.present? ? "#{resource.resource_publication&.publication_name}, " : ''
      str += resource.resource_publication&.manuscript_number&.presence || ''
      if resource.manuscript.present?
        status = (resource.manuscript.accepted? && 'accepted') || (resource.manuscript.rejected? && 'rejected') || 'submitted'
        str += "<span id=\"status-label\" class=\"#{status}\">#{status}</span>"
      end
      str += '<span id="doi-label" class="accepted">published</span>' if resource.identifier.publication_article_doi.present?
      unless resource.related_identifiers.empty?
        str += "<br/>#{resource.related_identifiers.size} related work#{resource.related_identifiers.size > 1 ? 's' : ''}"
      end
      str.html_safe
    end

    def format_external_references(instring)
      return '' unless instring.present?

      # Stripe invoice references
      if instring.start_with?('in_') && !instring.start_with?('in_progress')
        return render inline: link_to('invoice', "https://dashboard.stripe.com/invoices/#{instring}",
                                      target: :_blank)
      end

      # Turn salesforce references into hyperlinks
      matchdata = instring.match(/(.*)SF ?#? ?(\d+)(.*)/)
      return instring unless matchdata

      sf_link = Stash::Salesforce.case_view_url(case_num: matchdata[2])
      return instring unless sf_link.present?

      render inline: matchdata[1] + link_to("SF #{matchdata[2]}", sf_link, target: :_blank) + matchdata[3]
    end

    def link_to_account(type, id)
      href = if type&.start_with?('institution')
               tenant_admin_path(q: id)
             elsif type&.start_with?('journal')
               journal_admin_path(q: id)
             end
      return format_external_references(id) if href.nil?

      link_to id, href, target: '_blank'
    end

    def salesforce_links(doi)
      Stash::Salesforce.find_cases_by_doi(doi)
    end
  end
end
