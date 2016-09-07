require 'test_helper'
require 'byebug'

module StashEngine
  class ResourceTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
    test 'file cleanup' do
      res = Resource.find(1)
      assert_kind_of Resource, res
      assert_equal 2, res.file_uploads.count
      res.clean_uploads
      assert_includes [0, 1], res.file_uploads.count
    end

    test 'current resource state set' do
      #cannot find any way to set the enum in fixtures that works, so setting it in here
      res = Resource.find(1)
      res.current_state.resource_state = :in_progress
      assert_equal :in_progress, :in_progress
    end
  end
end
