require 'spec_helper'
require 'stash/harvester_app'

module Stash
  module HarvesterApp
    RSpec.describe 'yaml config' do

      before(:context) do
        yaml_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'data'))
        @single_set_yaml = File.join(yaml_dir, 'stash-harvester.yml')
        @multi_set_yaml = File.join(yaml_dir, 'stash-harvester-sets.yml')
      end

      it 'returns normal config path for a single set' do
        shim = ConfigFileShim.new(@single_set_yaml)
        expect(shim.configs.first).to eq(@single_set_yaml)
      end

      it 'returns two configs for two sets' do
        shim = ConfigFileShim.new(@multi_set_yaml)
        expect(shim.configs.length).to eq(2)
        shim.cleanup
      end
    end
  end
end
