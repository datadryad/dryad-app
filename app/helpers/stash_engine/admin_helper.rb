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
        link_to '<i class="fas fa-receipt" aria-hidden="true"></i>'.html_safe, payment_details_identifier_path(id: identifier_id),
                { 'aria-label': 'Developer details', title: 'Developer details' }
      end
    end

    def payer_payment_details_debugger(payer)
      return unless current_user.system_user?

      content_tag :div do
        link_to '<i class="fas fa-receipt" aria-hidden="true"></i>'.html_safe, payment_details_sponsor_path(id: payer.id, type: payer.class.name),
                { 'aria-label': 'Payment details', title: 'Payment details' }
      end
    end
  end
end
