require_relative '../../stash/script/counter-uploader/submitted_reports'
require_relative '../../stash/script/counter-uploader/uploader'
require 'webmock/rspec'
require 'byebug'
require 'digest'
require 'zlib'
require 'stringio'

RSpec.describe SubmittedReports do
  before(:each) do
    WebMock.disable_net_connect!
    @sr = SubmittedReports.new
  end

  describe '#list_reports' do
    it 'returns a list of reports' do
      stub_request(:get, 'https://api.datacite.org/reports?client-id=cdl.dash&page%5Bsize%5D=500')
        .with(headers: { 'Host' => 'api.datacite.org' })
        .to_return(status: 200, body: File.read(File.join(__dir__, '../fixtures/http_responses/datacite_reports.json')),
                   headers: { 'content-type' => 'application/json; charset=utf-8' })
      result = @sr.list_reports
      rpt = result['2013-10']
      expect(rpt.year_month).to eq('2013-10')
      expect(rpt.id).to eq('024ba999-9999-4ca6-8875-a2ba33187666')
    end

    it 'raises an error' do
      stub_request(:get, 'https://api.datacite.org/reports?client-id=cdl.dash&page%5Bsize%5D=500')
        .with(headers: { 'Host' => 'api.datacite.org' })
        .to_return(status: 500, body: 'internal server error')
      expect { @sr.list_reports(retries: 1) }.to raise_error(/Bad response from DataCite/)
    end
  end

  describe '#add_page_counts' do
    before(:each) do
      stub_request(:get, 'https://api.datacite.org/reports?client-id=cdl.dash&page%5Bsize%5D=500')
        .with(headers: { 'Host' => 'api.datacite.org' })
        .to_return(status: 200, body: File.read(File.join(__dir__, '../fixtures/http_responses/datacite_reports.json')),
                   headers: { 'content-type' => 'application/json; charset=utf-8' })

      stub_request(:get, %r{api\.datacite\.org/events\?source-id=datacite-usage&subj-id=https://api\.datacite\.org/reports/.+})
        .with(headers: { 'Host' => 'api.datacite.org' })
        .to_return(status: 200,
                   body: { "data": [], "meta": { "total": 15, "total-pages": 2, "page": 1 },
                           "links": { "self": 'fill' } }.to_json,
                   headers: { 'content-type' => 'application/json; charset=utf-8' })
    end

    it 'add the page counts by a different query' do
      @sr.list_reports
      @sr.add_page_counts
      rep = @sr.reports['2013-10']
      expect(rep.pages).to eq(2)
    end

  end
end

RSpec.describe Uploader do

  # make these private methods public so we can test them by reopening the class
  Uploader.class_eval do
    public :modify_headers, :compress, :send_file
  end

  before(:each) do
    @up = Uploader.new(report_id: nil, file_name: File.expand_path(File.join(__dir__, '../fixtures/2010-11.json')))
  end

  describe '#modify_headers' do
    it "modifies headers to say it's compressed" do
      @up.modify_headers
      report = File.read(File.expand_path(File.join(__dir__, '../../stash/script/counter-uploader/tmp/fixed_large_report.json')))
      report = JSON.parse(report)
      exc = report['report-header']['exceptions'].first
      expect(exc['code']).to eq(69)
      expect(exc['severity']).to eq('warning')
      expect(exc['message']).to eq('Report is compressed using gzip')
      expect(exc['help-url']).to eq('https://github.com/datacite/sashimi')
      expect(exc['data']).to eq('usage data needs to be uncompressed')
    end
  end

  describe '#compress' do
    it 'correctly compresses the file' do
      @up.modify_headers  # sets up the correct file to compress
      filepath = File.expand_path(File.join(__dir__, '../../stash/script/counter-uploader/tmp/fixed_large_report.json'))
      str = @up.compress(filepath)
      uncompressed = Zlib::GzipReader.new(StringIO.new(str)).read
      expect(uncompressed).to eq(File.read(filepath))
    end
  end

  describe '#send_file' do
    it 'sends the file it has to DataCite' do
      ENV['TOKEN'] = '12xup3856'
      stub_request(:post, 'https://api.datacite.org/reports')
        .with(headers: {
                'Accept' => 'gzip',
                'Authorization' => 'Bearer 12xup3856',
                'Connection' => 'close',
                'Content-Encoding' => 'gzip',
                'Content-Type' => 'application/gzip',
                'Host' => 'api.datacite.org'
              })
        .to_return(status: 200,
                   body: '{ "report": { "id": "7788394xxx" } }',
                   headers: { 'content-type' => 'application/json; charset=utf-8' })

      @up.modify_headers  # sets up the correct file to compress
      filepath = File.expand_path(File.join(__dir__, '../../stash/script/counter-uploader/tmp/fixed_large_report.json'))
      resp_id = @up.send_file(filepath)
      expect(resp_id).to eq('7788394xxx')
    end
  end
end
