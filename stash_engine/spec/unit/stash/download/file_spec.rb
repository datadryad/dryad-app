require 'spec_helper'
require 'stash/download/file'
require 'ostruct'

# a base class for version and file downloads, providing some basic functions
module Stash
  module Download
    describe 'File' do

      describe '#download' do

        before(:each) do
          @file = File.new(controller_context: OpenStruct.new(response_body:  '',
                                                              response: OpenStruct.new(headers: {})))
          @file_upload = create(:file_upload)
          allow(@file_upload).to receive(:merritt_express_url).and_return('http://grah.example.com')
          allow(@file_upload).to receive_message_chain('resource.tenant') { 'hi, not really used' }
        end

        it 'sets the @file automatically before downloading' do
          allow(@file).to receive(:stream_response).and_return(nil)
          @file.download(file: @file_upload)
          expect(@file_upload).to eql(@file.file)
        end
      end

      describe '#disposition_filename' do
        before(:each) do
          @file_upload = create(:file_upload, upload_file_name: 'go/to/Sidlauskas 2007 Data.xls')
          @file = File.new(controller_context: OpenStruct.new(response_body:  '',
                                                              response: OpenStruct.new(headers: {})))
          @file.file = @file_upload
        end

        it 'includes content-disposition to have attachment and set the filename' do
          expect(@file.disposition_filename).to match(/attachment; filename=".+"/)
        end

        it 'removes any path in the filename and places it in the filename' do
          expect(@file.disposition_filename).to eql('attachment; filename="Sidlauskas 2007 Data.xls"')
        end
      end
    end
  end
end
