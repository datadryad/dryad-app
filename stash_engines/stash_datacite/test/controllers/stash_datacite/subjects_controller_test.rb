require 'test_helper'

module StashDatacite
  class SubjectsControllerTest < ActionController::TestCase
=begin
    setup do
      @subject = stash_datacite_subjects(:one)
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:subjects)
    end

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'should create subject' do
      assert_difference('Subject.count') do
        post :create, subject: {  }
      end

      assert_redirected_to subject_path(assigns(:subject))
    end

    test 'should show subject' do
      get :show, id: @subject
      assert_response :success
    end

    test 'should get edit' do
      get :edit, id: @subject
      assert_response :success
    end

    test 'should update subject' do
      patch :update, id: @subject, subject: {  }
      assert_redirected_to subject_path(assigns(:subject))
    end

    test 'should destroy subject' do
      assert_difference('Subject.count', -1) do
        delete :destroy, id: @subject
      end

      assert_redirected_to subjects_path
    end
=end
  end
end
