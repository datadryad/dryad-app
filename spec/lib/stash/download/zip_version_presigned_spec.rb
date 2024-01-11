require 'stash/download/zip_version_presigned'
require 'byebug'
require 'securerandom'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Download
    RSpec.describe ZipVersionPresigned do
      before(:each) do
        @resource = create(:resource, tenant_id: 'dryad')
        @data_file = create(:data_file, resource_id: @resource.id)

        @controller_context = double
        allow(@controller_context).to receive(:redirect_to).and_return('redirected')
        allow(@controller_context).to receive(:render).and_return('rendered 405')
      end

      describe '#valid_resource?' do
        it 'is false if resource is blank' do
          @resource = nil
          vp = ZipVersionPresigned.new(resource: @resource, controller_context: @controller_context)
          expect(vp.valid_resource?).to be_falsey
        end

        it 'is false if tenant is blank' do
          @resource.tenant_id = 'grobber'
          vp = ZipVersionPresigned.new(resource: @resource, controller_context: @controller_context)
          expect(vp.valid_resource?).to be_falsey
        end

        it 'is false if version is blank' do
          @resource.stash_version.destroy!
          @resource.reload
          vp = ZipVersionPresigned.new(resource: @resource, controller_context: @controller_context)
          expect(vp.valid_resource?).to be_falsey
        end
      end

      describe '#download' do
        it 'returns 405 error if file size is too large' do
          @resource.total_file_size = 400
          vp = ZipVersionPresigned.new(resource: @resource, controller_context: @controller_context)
          expect(vp.download(resource: @resource)).to eq('rendered 405')
        end

        it 'redirects to a url' do
          @resource.total_file_size = 100
          vp = ZipVersionPresigned.new(resource: @resource, controller_context: @controller_context)
          expect(vp.download(resource: @resource)).to eq('redirected')
        end
      end

    end
  end
end
