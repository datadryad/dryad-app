require 'spec_helper'
require 'stash/harvester_app'

module Stash
  module HarvesterApp
    describe Options do

      describe '#new' do
        it 'works with no args' do
          options = Options.new
          expect(options.show_version).to be_falsey
          expect(options.show_help).to be_falsey
          expect(options.from_time).to be_nil
          expect(options.until_time).to be_nil
          expect(options.config_file).to be_nil
          expect(options.stop_file).to be_nil
        end

        it 'takes an empty array' do
          options = Options.new([])
          expect(options.show_version).to be_falsey
          expect(options.show_help).to be_falsey
          expect(options.from_time).to be_nil
          expect(options.until_time).to be_nil
          expect(options.config_file).to be_nil
          expect(options.stop_file).to be_nil
        end

        it 'takes an array' do
          options = Options.new(%w(-c elvis))
          expect(options.config_file).to eq('elvis')
        end

        it 'takes a single string' do
          options = Options.new('-h')
          expect(options.show_help).to be true
        end
      end

      describe '#show_help' do
        it 'parses -h' do
          options = Options.new('-h')
          expect(options.show_help).to be true
        end

        it 'parses --help' do
          options = Options.new('--help')
          expect(options.show_help).to be true
        end
      end

      describe '#show_version' do
        it 'parses -v' do
          options = Options.new('-v')
          expect(options.show_version).to be true
        end

        it 'parses --version' do
          options = Options.new('-v')
          expect(options.show_version).to be true
        end
      end

      describe '#from_time' do
        it 'parses -f' do
          time = Time.utc(2001, 2, 3, 4, 5, 6)
          options = Options.new(['-f', time.iso8601])
          expect(options.from_time).to be_time(time)
        end

        it 'parses --from' do
          time = Time.utc(2001, 2, 3, 4, 5, 6)
          options = Options.new(['--from', time.iso8601])
          expect(options.from_time).to be_time(time)
        end

        it 'parses a date' do
          options = Options.new(%w(--from 2015-01-01))
          expect(options.from_time).to be_time(Time.utc(2015, 1, 1))
        end

        it 'parses a datetime' do
          options = Options.new(%w(--from 2015-01-01T12:34:56Z))
          expect(options.from_time).to be_time(Time.utc(2015, 1, 1, 12, 34, 56))
        end

        it 'gives a sensible error if no value provided' do
          %w(-f --from).each do |opt|
            expect { Options.new([opt]) }.to raise_error do |error|
              expect(error).to be_an(OptionParser::MissingArgument)
              expect(error.message).to include(opt)
            end
          end
        end

        it 'gives a sensible error for malformed values' do
          arg = '15-Jan-2015'
          expect { Options.new(['--from', arg]) }.to raise_error do |error|
            expect(error).to be_an(OptionParser::InvalidArgument)
            expect(error.message).to include(arg)
          end
        end
      end

      describe '#until_time' do
        it 'parses -u' do
          time = Time.utc(2001, 2, 3, 4, 5, 6)
          options = Options.new(['-u', time.iso8601])
          expect(options.until_time).to be_time(time)
        end

        it 'parses --until' do
          time = Time.utc(2001, 2, 3, 4, 5, 6)
          options = Options.new(['--until', time.iso8601])
          expect(options.until_time).to be_time(time)
        end

        it 'parses a date' do
          options = Options.new(%w(--until 2015-01-01))
          expect(options.until_time).to be_time(Time.utc(2015, 1, 1))
        end

        it 'parses a datetime' do
          options = Options.new(%w(--until 2015-01-01T12:34:56Z))
          expect(options.until_time).to be_time(Time.utc(2015, 1, 1, 12, 34, 56))
        end

        it 'gives a sensible error if no value provided' do
          %w(-u --until).each do |opt|
            expect { Options.new([opt]) }.to raise_error do |error|
              expect(error).to be_an(OptionParser::MissingArgument)
              expect(error.message).to include(opt)
            end
          end
        end

        it 'gives a sensible error for malformed values' do
          arg = '15-Jan-2015'
          expect { Options.new(['--until', arg]) }.to raise_error do |error|
            expect(error).to be_an(OptionParser::InvalidArgument)
            expect(error.message).to include(arg)
          end
        end
      end

      describe '#config_file' do
        it 'parses -c' do
          file = '/home/foo/stash-harvester.yml'
          options = Options.new(['-c', file])
          expect(options.config_file).to eq(file)
        end

        it 'parses --config' do
          file = '/home/foo/stash-harvester.yml'
          options = Options.new(['--config', file])
          expect(options.config_file).to eq(file)
        end

        it 'gives a sensible error if no value provided' do
          %w(-c --config).each do |opt|
            expect { Options.new([opt]) }.to raise_error do |error|
              expect(error).to be_an(OptionParser::MissingArgument)
              expect(error.message).to include(opt)
            end
          end
        end
      end

      describe '#stop_file' do
        it 'parses -s' do
          file = '/home/foo/stash-harvester.stop'
          options = Options.new(['-s', file])
          expect(options.stop_file).to eq(file)
        end

        it 'parses --stop-file' do
          file = '/home/foo/stash-harvester.stop'
          options = Options.new(['--stop-file', file])
          expect(options.stop_file).to eq(file)
        end

        it 'gives a sensible error if no value provided' do
          %w(-s --stop-file).each do |opt|
            expect { Options.new([opt]) }.to raise_error do |error|
              expect(error).to be_an(OptionParser::MissingArgument)
              expect(error.message).to include(opt)
            end
          end
        end

        describe '#stop_file_present' do
          it 'returns false for nonexistent files' do
            path = "/home/foo/missing-#{Time.now.to_i}"
            expect(File.exist?(path)).to be_falsey # just to be sure
            options = Options.new
            options.stop_file = path
            expect(options.stop_file_present).to be_falsey
          end

          it 'returns true for files that exist' do
            file = Tempfile.new('stopfile-test')
            begin
              path = file.path
              expect(File.exist?(path)).to be_truthy # just to be sure
              options = Options.new
              options.stop_file = path
              expect(options.stop_file_present).to be_truthy
            ensure
              file.unlink
            end
          end
        end
      end

      describe '#do_exit' do
        it 'returns true for help' do
          %w(-h --help).each do |arg|
            options = Options.new(arg)
            expect(options.do_exit).to be_truthy
          end
        end

        it 'returns true for version' do
          %w(-v --version).each do |arg|
            options = Options.new(arg)
            expect(options.do_exit).to be_truthy
          end
        end

        it 'returns true if stopfile present' do
          file = Tempfile.new('stopfile-test')
          begin
            path = file.path
            expect(File.exist?(path)).to be_truthy # just to be sure
            options = Options.new
            options.stop_file = path
            expect(options.do_exit).to be_truthy
          ensure
            file.unlink
          end
        end

        it 'returns true for help and version together' do
          %w(-h --help).each do |h|
            %w(-v --version).each do |v|
              [[h, v], [v, h]].each do |args|
                options = Options.new(args)
                expect(options.do_exit).to be_truthy
              end
            end
          end
        end
      end

    end
  end
end
