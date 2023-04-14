require 'byebug'
require 'http'
require 'json'

# most of the uploading code I got from examples from DataCite at
# https://support.datacite.org/docs/usage-reports-api-guide

class Uploader

  LARGE_FILE_EXCEPTION = { code: 69, severity: 'warning', message: 'Report is compressed using gzip',
                           'help-url': 'https://github.com/datacite/sashimi', data: 'usage data needs to be uncompressed' }.freeze

  URI = 'https://api.datacite.org/reports'.freeze

  def initialize(file_name:, report_id: nil)
    @report_id = report_id
    @file_name = file_name
    @http = HTTP.timeout(connect: 120, read: 120).timeout(120).follow(max_hops: 10)
  end

  def process
    modify_headers
    send_file(Rails.root.join('tmp/fixed_large_report.json'))
  end

  private

  def modify_headers
    string = File.open(@file_name, 'r:UTF-8', &:read)
    hash = JSON.parse(string)
    if hash['report-header']['exceptions'].length == 1 && hash['report-header']['exceptions'].first == {}
      hash['report-header']['exceptions'].first.merge!(LARGE_FILE_EXCEPTION)
    else
      hash['report-header']['exceptions'].push(LARGE_FILE_EXCEPTION)
    end

    string = hash.to_json
    File.open(Rails.root.join('tmp/fixed_large_report.json'), 'w:UTF-8') { |f| f.write(string) }
  end

  def compress(file)
    report = File.read(file)
    gzip = Zlib::GzipWriter.new(StringIO.new)
    gzip << report
    gzip.close.string
  end

  def send_file(file)
    headers = {
      content_type: 'application/gzip',
      content_encoding: 'gzip',
      accept: 'gzip',
      authorization: "Bearer #{APP_CONFIG[:counter][:token]}"
    }

    body = compress(file)

    resp = nil
    12.times do |i|
      puts "  Try #{1}"
      resp =
        if @report_id.nil?
          @http.post(URI, body: body, headers: headers)
        else
          @http.put("#{URI}/#{@report_id}", body: body, headers: headers)
        end
      break if resp.status.code.between?(200, 299)

      puts "  Status code #{resp.status.code}"
      puts "  Response body: \n #{resp.body}"

      sleep 5
    end

    json = resp.parse

    json['report']['id']
  end
end
