require 'test_helper'

class StashEngineTest < ActiveSupport::TestCase
  StashEngine.setup do |config|
    fn = File.join(Rails.root, '..', '..', 'test', 'files', 'ucop.yml')
    config.tenants = {:cdl => HashWithIndifferentAccess.new(YAML.load_file(fn))}
  end

  test "truth" do
    assert_kind_of Module, StashEngine, "module test"
  end

  test "loaded tenants" do
    assert_equal 1, StashEngine.tenants.keys.count
    assert_equal 'merritt', StashEngine.tenants[:cdl][:repository][:type]
    assert_equal 'cdl', StashEngine.tenants[:cdl][:tenant_id]
  end
end
