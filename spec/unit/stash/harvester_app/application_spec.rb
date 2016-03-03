require 'spec_helper'
require 'stash/harvester_app'

require 'tmpdir'
require 'fileutils'

module Stash
  module HarvesterApp

    describe Application do

      before :each do
        @wd = '/stash/apps/stash-harvester'
        allow(Dir).to receive(:pwd) { @wd }

        @home = '/home/stash'
        allow(Dir).to receive(:home) { @home }
      end

      after :each do
        allow(Dir).to receive(:pwd).and_call_original
        allow(Dir).to receive(:home).and_call_original
      end

      describe '#config_file_defaults' do
        it 'prefers ./stash-harvester.yml, then ~/.stash-harvester.yml' do
          expected = %w(/stash/apps/stash-harvester/stash-harvester.yml /home/stash/.stash-harvester.yml)
          expect(Application.config_file_defaults).to eq(expected)
        end
      end

      describe '#config' do

        after :each do
          allow(Config).to receive(:from_file).and_call_original
          allow(File).to receive(:exist?).and_call_original
        end

        it 'reads the specified file' do
          config_file = '/etc/stash-harvester.yml'

          # Trust the Config class to check for nonexistent files
          config = instance_double(Config)
          expect(Config).to receive(:from_file).with(config_file).and_return(config)

          app = Application.new(config_file: config_file)
          expect(app.config).to be(config)
        end

        it 'defaults to plain file in the current working directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(true)

          config = instance_double(Config)
          expect(Config).to receive(:from_file).with(wd_config_path).and_return(config)

          app = Application.new
          expect(app.config).to be(config)
        end

        it 'falls back to dotfile in the user home directory' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(false)

          home_config_path = "#{@home}/.stash-harvester.yml"
          expect(File).to receive(:exist?).with(home_config_path).and_return(true)

          config = instance_double(Config)
          expect(Config).to receive(:from_file).with(home_config_path).and_return(config)

          app = Application.new
          expect(app.config).to be(config)
        end

        it 'raises ArgumentError if passed nil and no default found' do
          wd_config_path = "#{@wd}/stash-harvester.yml"
          expect(File).to receive(:exist?).with(wd_config_path).and_return(false)

          home_config_path = "#{@home}/.stash-harvester.yml"
          expect(File).to receive(:exist?).with(home_config_path).and_return(false)

          expect { Application.new }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            expect(e.message).to include "#{@wd}/stash-harvester.yml"
            expect(e.message).to include "#{@home}/.stash-harvester.yml"
          end
        end
      end

    end
  end
end
