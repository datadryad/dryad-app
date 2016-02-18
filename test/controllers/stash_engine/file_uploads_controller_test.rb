require 'test_helper'

module StashEngine
  class FileUploadsControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should destroy file" do
      fu = FileUpload.find(1)
      assert_equal fu.upload_file_name, 'cat.txt'
      assert File.exist?(fu.temp_file_path)
      assert_difference('FileUpload.count', -1) do
        delete :destroy, {id: fu.id, format: :js}, {user_id: 1}
      end
    end


    #test "should get edit" do
    #  get :edit
    #  assert_response :success
    #end

    #test "should get delete" do
    #  get :delete
    #  assert_response :success
    #end
  end
end
