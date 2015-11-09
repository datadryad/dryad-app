require 'test_helper'

module StashEngine
  class TenantTest < ActiveSupport::TestCase
    test "tenants loaded" do
      assert_equal 11, Tenant.all.length
      assert_equal Tenant.all.first.tenant_id, 'dataone'
    end

    test "find" do
      assert_instance_of StashEngine::Tenant, Tenant.find('ucb')
      assert_equal "UC Berkeley", Tenant.find('ucb').short_name
    end


  end
end
