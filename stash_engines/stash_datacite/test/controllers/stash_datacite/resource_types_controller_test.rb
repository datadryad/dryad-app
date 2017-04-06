require 'test_helper'

module StashDatacite
  class ResourceTypesControllerTest < ActionController::TestCase
=begin
    setup do
      @resource_type = stash_datacite_resource_types(:one)
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:resource_types)
    end

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'should create resource_type' do
      assert_difference('ResourceType.count') do
        post :create, resource_type: {  }
      end

      assert_redirected_to resource_type_path(assigns(:resource_type))
    end

    test 'should show resource_type' do
      get :show, id: @resource_type
      assert_response :success
    end

    test 'should get edit' do
      get :edit, id: @resource_type
      assert_response :success
    end

    test 'should update resource_type' do
      patch :update, id: @resource_type, resource_type: {  }
      assert_redirected_to resource_type_path(assigns(:resource_type))
    end

    test 'should destroy resource_type' do
      assert_difference('ResourceType.count', -1) do
        delete :destroy, id: @resource_type
      end

      assert_redirected_to resource_types_path
    end
=end
  end
end
