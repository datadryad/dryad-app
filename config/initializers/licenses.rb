require 'yaml'
require 'ostruct'
lic = File.join(Rails.root, 'config', 'licenses.yml')
if File.exists?(lic)
  LICENSES = YAML.load_file(lic).with_indifferent_access
end