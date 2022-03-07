require 'ostruct'
require 'yaml'

# this will interpret any ERB in the yaml file first before bringing in
ac = YAML.load(ERB.new(File.read(File.join(Rails.root, 'config', 'app_config.yml'))).result)[Rails.env]

ac[:app_version] = (File.exist?(Rails.root.join('.version')) ? File.read(Rails.root.join('.version')) : '' )
ac[:app_revision] = (File.exist?(Rails.root.join('REVISION')) ? File.read(Rails.root.join('REVISION')) : '' )

# this will make the config available under the APP_CONFIG constant and methods like APP_CONFIG.contact_email
APP_CONFIG = ac.to_ostruct

ENV['SSL_CERT_FILE'] = APP_CONFIG.ssl_cert_file if APP_CONFIG.ssl_cert_file

if `uname -r`.include?('amzn') # only install on our amazon servers
  ENV['PYENV_ROOT']='/dryad/.pyenv'
  ENV['PATH']="/dryad/.pyenv/bin:#{ENV['PATH']}"
end
