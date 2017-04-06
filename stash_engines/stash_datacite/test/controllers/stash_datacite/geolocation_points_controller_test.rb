require 'test_helper'

module StashDatacite
  class GeolocationPointsControllerTest < ActionController::TestCase
=begin
    setup do
      @geolocation_point = stash_datacite_geolocation_points(:one)
      @routes = Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
      assert_not_nil assigns(:geolocation_points)
    end

    test 'should get new' do
      get :new
      assert_response :success
    end

    test 'should create geolocation_point' do
      assert_difference('GeolocationPoint.count') do
        post :create, geolocation_point: {  }
      end

      assert_redirected_to geolocation_point_path(assigns(:geolocation_point))
    end

    test 'should show geolocation_point' do
      get :show, id: @geolocation_point
      assert_response :success
    end

    test 'should get edit' do
      get :edit, id: @geolocation_point
      assert_response :success
    end

    test 'should update geolocation_point' do
      patch :update, id: @geolocation_point, geolocation_point: {  }
      assert_redirected_to geolocation_point_path(assigns(:geolocation_point))
    end

    test 'should destroy geolocation_point' do
      assert_difference('GeolocationPoint.count', -1) do
        delete :destroy, id: @geolocation_point
      end

      assert_redirected_to geolocation_points_path
    end
=end
  end
end
