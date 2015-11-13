require 'test_helper'

module StashEngine
  class TenantsControllerTest < ActionController::TestCase
    setup do
      @routes = StashEngine::Engine.routes
    end

    test "should get index" do
      get :index #, use_route: 'stash_engine'
      assert_response :success
      assert_not_nil assigns(:tenants)
    end

    test "should show tenant" do
      session[:test_domain] = 'test.berkeley.edu'
      get :show, id: 'ucb'
      assert_response :success
    end

  end
end
