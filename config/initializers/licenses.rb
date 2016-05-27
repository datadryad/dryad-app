require 'yaml'
require 'ostruct'
licenses = YAML.load_file(File.join(Rails.root, 'config', 'licenses.yml'))

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.metadata_engines
LICENSES = OpenStruct.new(licenses)