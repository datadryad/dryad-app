require 'json'
require 'http'
require 'cgi'

# this gets the submitted reports and puts them into a hash with key of yyyy-mm and key and report
# example:
# [ '2013-01': {id: '05965e5d-99b9-4c09-e728fa518748', pages: 5}, '2013-02': {id: '05965e5d-99b9-4c09-aaa1', pages: 7 }]
class ReportInfo
  attr_accessor :year_month, :id, :pages

  def initialize(year_month:, id:, pages: nil)
    @year_month = year_month
    @id = id
    @pages = pages
  end
end

class SubmittedReports
  attr_reader :reports

  def initialize
    @reports = nil
    @http = HTTP.timeout(connect: 120, read: 120).timeout(120).follow(max_hops: 10)
  end

  def process_reports
    list_reports
    add_page_counts
  end

  def list_reports(retries: 12)
    puts 'Asking for list of reports from DataCite.  This might take a long while.'

    resp = get_with_retries("https://api.datacite.org/reports?client-id=#{APP_CONFIG[:counter][:account]}&page[size]=500", retries: retries)

    json = resp.parse

    hsh = {}

    json['reports'].each do |r|
      yyyy_mm = r['report-header']['reporting-period']['begin-date'][0..6]
      hsh[yyyy_mm] = ReportInfo.new(id: r['id'], year_month: yyyy_mm)
    end

    @reports = hsh
  end

  def add_page_counts
    @reports.each_with_index do |(_year_month, report), index|
      subj_id = "https://api.datacite.org/reports/#{report.id}"
      str = "https://api.datacite.org/events?source-id=datacite-usage&subj-id=#{CGI.escape(subj_id)}"
      puts "#{index + 1}/#{@reports.length} Getting page count for #{report.year_month}\t#{report.id}"

      resp = get_with_retries(str)
      json = resp.parse

      report.pages = json['meta']['total-pages']
      puts "pages: #{report.pages}\n\n"

      # resp['meta']['total'] == 0 || resp['meta']['total-pages'] == 0
    end
  end

  # The remote server can be unreliable
  def get_with_retries(url, retries: 12)
    resp = nil
    retries.times do
      resp = @http.get(url)
      break if resp.status.code.between?(200, 299)

      sleep 5
    end
    raise 'Bad response from DataCite' if resp.status.code != 200

    resp
  end
end
