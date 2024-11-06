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
  end
end
