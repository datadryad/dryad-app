module StashEngine
  RSpec.describe ResourcesController, type: :request do
    include DatabaseHelper

    context 'file uploads' do
      before(:each) do
        create_basic_dataset!
        allow_any_instance_of(ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
      end

      it 'asserts react root component' do
        @resource.current_resource_state.update(resource_state: 'in_progress')
        get "/stash/resources/#{@resource.id}/upload"

        assert_react_component 'UploadFiles' do |props|
          assert_equal @resource.id, props[:resource_id]
          assert_equal @resource.data_files.first.attributes, props[:file_uploads].first.stringify_keys
          assert_equal APP_CONFIG[:s3].to_h, props[:app_config_s3][:table]
          assert_equal @resource.s3_dir_name(type: 'base'), props[:s3_dir_name]
        end
      end
    end

  end
end
