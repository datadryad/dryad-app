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
      return unless current_user.superuser?

      content_tag :div do
        link_to 'Payment details page', identifier_payment_details_hidden_path(id: identifier_id)
      end
    end

    def payer_payment_details_debugger(payer)
      return unless current_user.superuser?

      link_to sponsor_payment_details_hidden_path(id: payer.id, type: payer.class.name), style: 'margin-left: 5px' do
        content_tag :i, nil, class: 'fa-solid fa-file-invoice-dollar'
      end
    end
  end
end
