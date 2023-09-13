module StashEngine
  RSpec.describe ResourcesController, type: :request do
    include DatabaseHelper
    include Mocks::Salesforce

    context 'file uploads' do
      before(:each) do
        mock_salesforce!
        create_basic_dataset!
        allow_any_instance_of(ResourcesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
        @resource.current_resource_state.update(resource_state: 'in_progress')
      end

      it 'loads react root component' do
        get "/stash/resources/#{@resource.id}/upload"

        assert_react_component 'containers/UploadFiles' do |props|
          assert_equal @resource.id, props[:resource_id]
          assert_equal @resource.data_files.first.attributes, props[:file_uploads].first.stringify_keys
          assert_equal APP_CONFIG[:s3].to_h.except(:secret), props[:app_config_s3][:table]
          assert_equal @resource.s3_dir_name(type: 'base'), props[:s3_dir_name]
          assert_equal APP_CONFIG[:frictionless].to_h, props[:frictionless]
        end
      end

      it 'loads files with respective frictionless reports if they exist' do
        file = @resource.generic_files.first
        StashEngine::FrictionlessReport.create(
          report: '[{errors: errors}]', generic_file: file, status: 'issues'
        )

        get "/stash/resources/#{@resource.id}/upload"

        assert_react_component 'containers/UploadFiles' do |props|
          assert_equal file.frictionless_report.status,
                       props[:file_uploads].first[:frictionless_report][:status]
        end
      end
    end

  end
end
