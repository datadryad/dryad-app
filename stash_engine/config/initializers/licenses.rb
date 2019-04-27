require 'yaml'
require 'ostruct'
lic = File.join(Rails.application.root, 'config', 'licenses.yml')
raise "License configuration file #{lic} not found" unless File.exist?(lic)
LICENSES = YAML.load_file(lic).with_indifferent_access
# the license stuff for example config is too much of a tangle to fix right now
# LICENSES = YAML.load(ERB.new(File.read(lic)).result)[Rails.env]
