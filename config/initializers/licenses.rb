require 'yaml'
require 'ostruct'
LICENSES = YAML.load_file(File.join(Rails.root, 'config', 'licenses.yml')).with_indifferent_access