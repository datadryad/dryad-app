require 'ostruct'
require 'yaml'

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.metadata_engines
APP_CONFIG = OpenStruct.new(YAML.load_file("#{Rails.root}/config/app_config.yml")[Rails.env])