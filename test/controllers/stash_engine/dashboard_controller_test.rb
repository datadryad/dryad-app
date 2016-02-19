require 'test_helper'

module StashEngine
  class DashboardControllerTest < ActionController::TestCase
    setup do
      @routes = StashEngine::Engine.routes
      session[:user_id] = 1
    end

    #test "should display dashboard" do
    #  get :show
    #  assert_response :success
    #end

    # test "the truth" do
    #   assert true
    # end
  end
end
