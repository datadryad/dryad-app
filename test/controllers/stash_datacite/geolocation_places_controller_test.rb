require 'test_helper'

module StashDatacite
  class GeolocationPlacesControllerTest < ActionController::TestCase
    setup do
      @geolocation_place = stash_datacite_geolocation_places(:one)
      @routes = Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:geolocation_places)
    end

    test "should get new" do
      get :new
      assert_response :success
    end

    test "should create geolocation_place" do
      assert_difference('GeolocationPlace.count') do
        post :create, geolocation_place: {  }
      end

      assert_redirected_to geolocation_place_path(assigns(:geolocation_place))
    end

    test "should show geolocation_place" do
      get :show, id: @geolocation_place
      assert_response :success
    end

    test "should get edit" do
      get :edit, id: @geolocation_place
      assert_response :success
    end

    test "should update geolocation_place" do
      patch :update, id: @geolocation_place, geolocation_place: {  }
      assert_redirected_to geolocation_place_path(assigns(:geolocation_place))
    end

    test "should destroy geolocation_place" do
      assert_difference('GeolocationPlace.count', -1) do
        delete :destroy, id: @geolocation_place
      end

      assert_redirected_to geolocation_places_path
    end
  end
end
