require 'yaml'
require 'ostruct'
lic = File.join(Rails.application.root, 'config', 'licenses.yml')
raise "License configuration file #{lic} not found" unless File.exists?(lic)
LICENSES = YAML.load_file(lic).with_indifferent_access