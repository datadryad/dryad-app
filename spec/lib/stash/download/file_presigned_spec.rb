# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/download/file_presigned'
require 'byebug'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Download
    RSpec.describe FilePresigned do

      before(:each) do
        @resource = create(:resource, tenant_id: 'dryad')
        @file_upload = create(:file_upload, resource_id: @resource.id)

        @controller_context = double
        allow(@controller_context).to receive(:redirect_to).and_return('redirected')
        allow(@controller_context).to receive(:render).and_return('rendered 404')

        @fp = FilePresigned.new(controller_context: @controller_context)
      end

      describe '#download(file:)' do

        before(:each) do
          @stubby = stub_request(:get, @file_upload.merritt_presign_info_url)
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

          stub_request(:get, @file_upload.merritt_presign_info_url)
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
