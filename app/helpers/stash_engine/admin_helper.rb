module StashEngine
  module AdminHelper
    def csv_headers(filename)
      headers.delete('Content-Length')
      headers['X-Accel-Buffering'] = 'no'
      headers['Cache-Control'] = 'no-cache'
      headers['Content-Type'] = 'text/csv; charset=utf-8'
      headers['Last-Modified'] = Time.now.ctime.to_s
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}_#{Time.new.strftime('%F')}.csv\""
    end

    def identifier_payment_details_debugger(identifier_id)
      return unless current_user.system_user?

      content_tag :div do
        link_to '<i class="fas fa-code" aria-hidden="true"></i>'.html_safe, payment_details_identifier_path(id: identifier_id),
                { 'aria-label': 'Developer details', title: 'Developer details' }
      end
    end

    def make_type(partner)
      partner.class.name.parameterize.sub('stashengine-', '').sub('tenant', 'institution').sub('journalorganization', 'publisher')
    end

    def payer_payment_details_debug_path(payer)
      payment_details_sponsor_path(id: payer.id, type: make_type(payer))
    end

    def payer_payment_details_path(sponsor)
      payment_commitments_path(sponsor_id: sponsor.id, type: make_type(sponsor))
    end

    def sponsor_paths(dynamic_path, sponsor)
      uri = URI.parse(dynamic_path)
      query_hash = URI.decode_www_form(uri.query || '').to_h
      query_hash.merge!(sponsor_id: sponsor.id, type: make_type(sponsor))

      uri.query = URI.encode_www_form(query_hash)
      uri.to_s
    end

    def partner_nav_list
      return if current_user.system_user?
      return if current_user.roles.admin_roles.length == 1

      current_user.roles.admin_roles.map do |role|
        link_to PayerDetailsService.new(role.role_object).details.name,
                partner_dashboard_path(type: make_type(role.role_object), id: role.role_object.id)
      end
    end
  end
end
