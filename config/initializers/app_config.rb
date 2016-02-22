require 'ostruct'
require 'yaml'
ac = YAML.load_file(File.join(Rails.root, 'config', 'app_config.yml'))[Rails.env]

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.metadata_engines
APP_CONFIG = OpenStruct.new(ac)