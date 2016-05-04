require 'spec_helper'

module Stash
  module Sword2
    module Client
      describe HTTPHelper do

        # ------------------------------------------------------------
        # Fixture

        attr_writer :user_agent

        def user_agent
          @user_agent ||= 'elvis'
        end

        attr_writer :helper

        def helper
          @helper ||= HTTPHelper.new(user_agent: user_agent)
        end

        # ------------------------------------------------------------
        # Tests

        describe '#post' do
          it 'posts to the specified URI'
          it 'sets the User-Agent header'
          it 'sets Basic-Auth headers'
          it 'uses SSL for https requests'
          describe 'continuation' do
            it 'sends Expect: 100-continue'
            it 'continues on a 100 Continue'
            it 'continues on a timeout in lieu of a 100 Continue'
            it 'redirects to post to a 302 Found'
            it 'fails on a 417 Expectation Failed'
          end
          describe 'responses' do
            it 'accepts a 200 OK'
            it 'accepts a 204 No Content'
            it 'accepts a 201 Created'
            it 'redirects to get a 303 See Other'
            it 'fails on a 4xx'
            it 'fails on a 5xx'
          end
        end

      end
    end
  end
end
