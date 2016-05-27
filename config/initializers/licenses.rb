require 'yaml'
licenses = YAML.load_file(File.join(Rails.root, 'config', 'app_config.yml'))

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.metadata_engines
LICENSES = OpenStruct.new(licenses)