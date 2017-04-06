require 'test_helper'

module StashDatacite
  class AuthorsControllerTest < ActionController::TestCase
=begin
    setup do
      @author = stash_datacite_authors(:one)
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:authors)
    end

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'should create author' do
      assert_difference('Author.count') do
        post :create, author: {  }
      end

      assert_redirected_to author_path(assigns(:author))
    end

    test 'should show author' do
      get :show, id: @author
      assert_response :success
    end

    test 'should get edit' do
      get :edit, id: @author
      assert_response :success
    end

    test 'should update author' do
      patch :update, id: @author, author: {  }
      assert_redirected_to author_path(assigns(:author))
    end

    test 'should destroy author' do
      assert_difference('Author.count', -1) do
        delete :destroy, id: @author
      end

      assert_redirected_to authors_path
    end
=end
  end
end
