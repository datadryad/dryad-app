require 'test_helper'

module StashEngine
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @routes = StashEngine::Engine.routes
    end

    test 'should get index' do
      get :index
      assert_response :success
    end

    test 'should destroy session' do
      session[:cat] = 'meow'
      get :destroy
      assert_response :redirect
      assert_empty session
    end

    test 'callback should set info' do
      @request.env['omniauth.auth'] =
          {
            info:
              {
                email:         'test@test.com',
                name:          'Test User',
                test_domain:   'test.berkeley.edu'
              },
            provider:     'developer',
            uid:          'test@test.com'
          }.with_indifferent_access
      get(:callback, 'provider' => 'developer')
      assert_response :redirect
      assert_equal 'test@test.com', session[:email]
    end

    test 'callback with bad info' do
      get(:callback, 'provider' => 'developer')
      assert_response 403
    end
  end
end
