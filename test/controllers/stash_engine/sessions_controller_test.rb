require 'test_helper'

module StashEngine
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @routes = StashEngine::Engine.routes
    end

    test 'should destroy session' do
      session[:user_id] = 1
      get :destroy
      assert_response :redirect
      assert_equal session[:user_id], nil
    end

    test 'callback should set info' do
      @request.env['omniauth.auth'] =
        OpenStruct.new({
          info:
            OpenStruct.new(email:         'test@test.com',
                           name:          'Test User',
                           test_domain:   'test.berkeley.edu'),
          credentials: OpenStruct.new(token: nil),
          provider:     'developer',
          uid:          'test@test.com'
        }.with_indifferent_access)

      get :callback, provider: 'developer'
      assert_response :redirect
      assert session['user_id']
      assert_equal User.find(session['user_id']).uid, 'test@test.com'
    end

    test 'callback with bad info' do
      get(:callback, 'provider' => 'developer')
      assert_response 403
    end
  end
end
