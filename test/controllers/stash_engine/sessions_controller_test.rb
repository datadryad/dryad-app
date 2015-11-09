require 'test_helper'

module StashEngine
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @routes = StashEngine::Engine.routes
    end

    test "should get index" do
      get :index
      assert_response :success
    end

  end
end
