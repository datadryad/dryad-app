require 'test_helper'

module StashEngine
  class FileUploadsControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
    end

    test 'should get new' do
      get :new
      assert_response :success
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
