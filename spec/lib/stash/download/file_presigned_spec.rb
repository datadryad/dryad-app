# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/download/file_presigned'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Download

    RSpec.describe FilePresigned do
      before(:each) do
        @resource = create(:resource)
        @file_upload = create(:file_upload, resource_id: @resource.id)

        @controller_context = double
        allow(@controller_context).to receive(:redirect_to).and_return('redirected')
        allow(@controller_context).to receive(:render).and_return('rendered 404')

        @fp = FilePresigned.new(controller_context: @controller_context)
      end

      describe '#handle_bad_status(r, file)' do
        it 'raises exception if r.status.success? is false' do
          r = double
          allow(r).to receive(:status).and_return({ 'success?': false }.to_ostruct)
          expect { @fp.handle_bad_status(r, @file_upload) }.to raise_error(Stash::Download::MerrittError)
        end
      end

      describe '#url(file:)' do
        it 'creates the url for a file' do
          ark = @resource.download_uri.match(/ark.+/).to_s
          resp = @fp.url(file: @file_upload)
          out_url = "http://merritt-fake.cdlib.org/api/presign-file/#{ark}/1/producer%2F" \
            "#{ERB::Util.url_encode(@file_upload.upload_file_name)}?no_redirect=true"
          expect(resp).to eq(out_url)
        end
      end

      describe '#download(file:)' do

        before(:each) do
          @stubby = stub_request(:get, @fp.url(file: @file_upload))
            .with(
              headers: {
                'Authorization' => 'Basic c3Rhc2hfc3VibWl0dGVyOmNvcnJlY3TigItob3JzZeKAi2JhdHRlcnnigItzdGFwbGU=',
                'Host' => 'merritt-fake.cdlib.org'
              }
            )
            .to_return(status: 200, body: '{"url":"https://my.testing.url.example.com"}',
                       headers: { 'Content-Type' => 'application/json' })
        end

        it 'redirects to a url' do
          resp = @fp.download(file: @file_upload)
          expect(resp).to eq('redirected')
        end

        it 'gives a 404 for missing file' do
          expect(@controller_context).to receive(:render)
          @fp.download(file: nil)
        end

        it 'raises an error for bad status response from Merritt' do
          remove_request_stub(@stubby)

          stub_request(:get, @fp.url(file: @file_upload))
            .with(
              headers: {
                'Authorization' => 'Basic c3Rhc2hfc3VibWl0dGVyOmNvcnJlY3TigItob3JzZeKAi2JhdHRlcnnigItzdGFwbGU=',
                'Host' => 'merritt-fake.cdlib.org'
              }
            )
            .to_return(status: 500, body: '{"url":"https://my.testing.url.example.com"}',
                       headers: { 'Content-Type' => 'application/json' })

          expect { @fp.download(file: @file_upload) }.to raise_error(Stash::Download::MerrittError)
        end
      end
    end
  end
end
