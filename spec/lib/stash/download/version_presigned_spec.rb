require 'stash/download/version_presigned'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Download
    RSpec.describe VersionPresigned do
      before(:each) do
        @resource = create(:resource)
        create(:download_token, resource_id: @resource.id)
        _ignored, @local_id = @resource.merritt_protodomain_and_local_id
        @vp = VersionPresigned.new(resource: @resource)
      end


      describe "urls for Merritt service" do
        it 'creates correct assemble_version_url' do
          u = @vp.assemble_version_url
          expect(u).to eq("https://localhost/api/assemble-version/#{ERB::Util.url_encode(@local_id)}/1?content=producer&format=zip")
        end

        it 'creates correct status_url' do
          u = @vp.status_url
          expect(u).to eq("https://localhost/api/presign-obj-by-token/#{@resource.download_token.token}" \
            "?filename=#{@vp.filename}&no_redirect=true")
        end
      end


    end
  end
end
