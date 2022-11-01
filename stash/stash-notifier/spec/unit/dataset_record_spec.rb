Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].sort.each { |file| require file }
require 'ostruct'
require 'nokogiri'

class DatasetRecordSpec
  describe 'dataset_record' do

    before(:each) do
      logger = double('logger')
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      allow(Config).to receive(:logger).and_return(logger)
      allow(Config).to receive(:oai_base_url).and_return('http://blah.example.org')

      @options = { metadata_prefix: 'stash_wrapper', from: '2018-12-01', until: '2019-02-01',
                   set: 'cats' }

      @oai_mock = double('oai')
      allow(::OAI::Client).to receive(:new).and_return(@oai_mock)
      # allow(@oai_mock).to receive(:list_records).and_return('fun')
      # allow(::OAI::Client).to receive(:new).and_return(@oai_mock)

    end

    describe '#oai_debugging_url' do
      it 'creates a correct url for debugging' do
        str = DatasetRecord.oai_debugging_url(base_url: 'http://blah.example.org',
                                              opts: @options)
        expect(str).to eql('http://blah.example.org?from=2018-12-01&metadataPrefix=stash_wrapper&set=cats&until=2019-02-01&verb=ListRecords')
      end
    end

    describe '#get_oai_response' do
      it 'handles OAI::Exception' do
        allow(@oai_mock).to receive(:list_records).with(any_args).and_raise(OAI::Exception.new(@oai_mock))
        resp = DatasetRecord.get_oai_response(@options)
        expect(resp).to eql(nil)
      end

      it 'handles Faraday::ConnectionFailed' do
        allow(@oai_mock).to receive(:list_records).with(any_args).and_raise(Faraday::ConnectionFailed.new(@oai_mock))
        resp = DatasetRecord.get_oai_response(@options)
        expect(resp).to eql(nil)
      end
    end

    describe '#initialize' do
      before(:each) do
        doc = File.open(File.join(__dir__, '..', 'data', 'oai-example.xml')) { |f| Nokogiri::XML(f) }
        @noko_raw = doc.xpath('/record/metadata').to_xml
        @noko_time = doc.xpath('/record/header/datestamp').text
        @noko_merritt_id = doc.xpath('/record/header/identifier').text

        @oai_record = double('oai-record-mock')
        allow(@oai_record).to receive(:metadata).and_return(@noko_raw)
        allow(@oai_record).to receive(:deleted?).and_return(nil)
        allow(@oai_record).to receive(:header).and_return(OpenStruct.new(datestamp: @noko_time, identifier: @noko_merritt_id))
        @my_record = DatasetRecord.new(@oai_record)
      end

      it 'sets deleted?' do
        expect(@my_record.deleted?).to eql(false)
      end

      it 'sets timestamp' do
        expect(@my_record.timestamp).to eql(Time.iso8601(@noko_time))
      end

      it 'sets doi' do
        expect(@my_record.doi).to eql('10.5072/dryad.jb3k0k7')
      end

      it 'sets merritt_id' do
        expect(@my_record.merritt_id).to eql('http://n2t.net/ark:/99999/fk47w7mr55')
      end

      it 'sets version' do
        expect(@my_record.version).to eql('2')
      end

      it 'sets title' do
        expect(@my_record.title).to eql('Data from: test workflow -- review')
      end
    end

  end
end
