require 'ostruct'
require 'yaml'

# this will interpret any ERB in the yaml file first before bringing in
ac = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'app_config.yml'))).result)[Rails.env]

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.metadata_engines
APP_CONFIG = ac.to_ostruct

ENV['SSL_CERT_FILE'] = APP_CONFIG.ssl_cert_file if APP_CONFIG.ssl_cert_file