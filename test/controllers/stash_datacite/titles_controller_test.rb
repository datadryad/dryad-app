require 'test_helper'

module StashDatacite
  class TitlesControllerTest < ActionController::TestCase
=begin
    setup do
      @title = stash_datacite_titles(:one)
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:titles)
    end

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'should create title' do
      assert_difference('Title.count') do
        post :create, title: {}
      end

      assert_redirected_to title_path(assigns(:title))
    end

    test 'should show title' do
      get :show, id: @title
      assert_response :success
    end

    test 'should get edit' do
      get :edit, id: @title
      assert_response :success
    end

    test 'should update title' do
      patch :update, id: @title, title: {}
      assert_redirected_to title_path(assigns(:title))
    end

    test 'should destroy title' do
      assert_difference('Title.count', -1) do
        delete :destroy, id: @title
      end

      assert_redirected_to titles_path
    end
=end
  end
end
