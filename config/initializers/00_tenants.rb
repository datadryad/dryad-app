hsh = ActiveSupport::HashWithIndifferentAccess.new

tenant_path = (Rails.env == 'test' ? File.join(Rails.root, 'dryad-config-example', 'tenants', '**.yml') :
                   File.join(Rails.root, 'config', 'tenants', '**.yml') )

# Read each tenant file into a hash, evaluating any ERB commands along the way
Dir.glob(tenant_path).each do |fn|
  h = ActiveSupport::HashWithIndifferentAccess.new(YAML.load(ERB.new(File.read(fn)).result)[Rails.env])
  hsh[h[:tenant_id]] = h
end

TENANT_CONFIG = hsh
