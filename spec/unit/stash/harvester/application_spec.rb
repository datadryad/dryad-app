require 'spec_helper'
require 'tmpdir'
require 'fileutils'

module Stash
  module Harvester
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
        it 'looks for plain file in the current working directory' do
          expect(Application.config_file_defaults).to include "#{@wd}/stash-harvester.yml"
        end

        it "looks for dotfile in the user's home directory" do
          expect(Application.config_file_defaults).to include "#{@home}/.stash-harvester.yml"
        end
      end

      describe '#ensure_config_file' do
        after :each do
          allow(Application).to receive(:default_config_file).and_call_original
        end

        it 'returns its argument, if non-nil' do
          config_file = '/etc/stash-harvester.yml'
          expect(Application.ensure_config_file(config_file)).to eq(config_file)
        end

        it 'falls back to #default_config_file, if passed nil' do
          default_config_file = '/etc/stash-harvester.yml'
          expect(Application).to receive(:default_config_file) { default_config_file }
          expect(Application.ensure_config_file(nil)).to eq(default_config_file)
        end

        it 'raises ArgumentError if passed nil and no default found' do
          expect(Application).to receive(:default_config_file) { nil }
          expect { Application.ensure_config_file(nil) }.to raise_error do |e|
            expect(e).to be_an ArgumentError
            expect(e.message).to include "#{@wd}/stash-harvester.yml"
            expect(e.message).to include "#{@home}/.stash-harvester.yml"
          end
        end
      end

      describe '#default_config_file' do
        it 'prefers plain file in current working directory' do
          Dir.mktmpdir do |dir|
            @wd = dir
            expected = '#{dir}/stash-harvester.yml'
            FileUtils.touch(expected)
            expect(Application.default_config_file).to eq(expected)
          end
        end

        it "falls back to dotfile in the user's home directory, if present" do
          Dir.mktmpdir do |dir|
            @home = dir
            expected = '#{dir}/.stash-harvester.yml'
            FileUtils.touch(expected)
            expect(Application.default_config_file).to eq(expected)
          end
        end

        it 'returns nil if neither default file is present' do
          expect(Application.default_config_file).to be_nil
        end
      end

    end
  end
end
