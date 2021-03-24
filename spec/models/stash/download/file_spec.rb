require 'stash/download/file'
require 'ostruct'
require_relative '../../../../stash/spec_helpers/factory_helper'

# a base class for version and file downloads, providing some basic functions
module Stash
  module Download
    describe 'File' do

      describe '#download' do

        before(:each) do
          # there is no db connection here so it blows up using real models
          @identifier = create(:identifier)
          @resource = create(:resource, identifier_id: @identifier.id)

          @file = File.new(controller_context: OpenStruct.new(response_body: '',
                                                              response: OpenStruct.new(headers: {})))
          @data_file = create(:data_file)
          allow(@data_file).to receive(:merritt_express_url).and_return('http://grah.example.com')
          allow(@data_file).to receive_message_chain('resource.tenant') { 'hi, not really used' }
          allow(@data_file).to receive_message_chain('resource.id') { 22 }
        end

        it 'sets the @file automatically before downloading' do
          allow(@file).to receive(:stream_response).and_return(nil)
          @file.download(file: @data_file)
          expect(@data_file).to eql(@file.file)
        end
      end

      describe '#disposition_filename' do
        before(:each) do
          @data_file = create(:data_file, upload_file_name: 'go/to/Sidlauskas 2007 Data.xls')
          @file = File.new(controller_context: OpenStruct.new(response_body: '',
                                                              response: OpenStruct.new(headers: {})))
          @file.file = @data_file
        end

        it 'removes any path in the filename and places it in the filename' do
          expect(@file.disposition_filename).to eql('Sidlauskas 2007 Data.xls')
        end
      end
    end
  end
end
