require 'test_helper'
require 'byebug'
module StashEngine
  class UserTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end

    test "creates from omniauth hash" do
      auth = {uid: 'testyuser', provider: 'oauth',
              info: { email: 'testing@test.com', name: 'Testy McTester' }.to_ostruct, credentials: {token: '12345'}.to_ostruct
        }.to_ostruct
      test = User.from_omniauth(auth, 'ucb')
    end
  end
end
