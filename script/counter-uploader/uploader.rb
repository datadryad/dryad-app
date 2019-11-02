require 'maremma'
require 'byebug'

# most of the uploading code I got from examples from DataCite at
# https://support.datacite.org/docs/usage-reports-api-guide

class Uploader

  LARGE_FILE_EXCEPTION =
      '"exceptions": [{"code": 69, "severity": "warning", "message": "Report is compressed using gzip", ' \
    '"help-url": "https://github.com/datacite/sashimi", "data": "usage data needs to be uncompressed"}]'.freeze

  NORMAL_EXCEPTION = '"exceptions": [{}]'.freeze

  URI = 'https://api.datacite.org/reports'.freeze


  def initialize(report_id: nil, file_name:)
    @report_id = report_id
    @file_name = file_name
  end

  def process
    modify_headers
    send_file('tmp/fixed_large_report.json')
  end

  private

  def modify_headers
    string = File.open(@file_name, "r:UTF-8", &:read)
    string = string.gsub(NORMAL_EXCEPTION, LARGE_FILE_EXCEPTION)
    File.open('tmp/fixed_large_report.json', 'w:UTF-8') {|f| f.write(string)}
  end

  def compress(file)
    report = File.read(file)
    gzip = Zlib::GzipWriter.new(StringIO.new)
    string = JSON.parse(report).to_json
    gzip << string
    body = gzip.close.string
    body
  end

  def send_file(file)

    headers = {
        content_type: "application/gzip",
        content_encoding: 'gzip',
        accept: 'gzip'
    }

    body = compress(file)

    response =
        if @report_id.blank?
          Maremma.post(URI, data: body,
                       bearer: ENV['TOKEN'],
                       headers: headers,
                       timeout: 100)
        else
          Maremma.put("#{URI}/#{@report_id}", data: body,
                      bearer: ENV['TOKEN'],
                      headers: headers,
                      timeout: 100)
        end
    raise "submission failed, got #{response.status} from server\r\n#{response.body}" if response.status < 200 || response.status > 299

    response['body']['data']['report']['id']
  end
end