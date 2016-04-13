require 'test_helper'

module StashEngine
  class ResourceStateTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
    test 'updates current resource after save' do
      rs = ResourceState.new
      rs.user_id = 1
      rs.resource_state = 'in_progress'
      rs.resource_id = 2
      rs.save!
      assert_equal rs.id, Resource.find(2).current_resource_state_id
    end
  end
end
