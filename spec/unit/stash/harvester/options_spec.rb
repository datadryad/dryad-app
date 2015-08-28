require 'stash/harvester/options'

module Stash
  module Harvester
    describe Options do

      it 'can provide a usage message'

      it 'provides sensible error reporting'

      describe '#new' do
        it 'works with no args' do
          options = Options.new
          expect(options.show_version).to be_falsey
          expect(options.show_help).to be_falsey
          expect(options.from_time).to be_nil
          expect(options.until_time).to be_nil
          expect(options.config_file).to be_nil
        end

        it 'takes an empty array' do
          options = Options.new([])
          expect(options.show_version).to be_falsey
          expect(options.show_help).to be_falsey
          expect(options.from_time).to be_nil
          expect(options.until_time).to be_nil
          expect(options.config_file).to be_nil
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
          options = Options.new(['-h'])
          expect(options.show_help).to be true
        end

        it 'parses --help' do
          options = Options.new(['--help'])
          expect(options.show_help).to be true
        end
      end

      describe ':version' do
        it 'parses -v'
        it 'parses --version'
      end

      describe ':from' do
        it 'parses -f'
        it 'parses --from'
        it 'parses a date'
        it 'parses a datetime'
        it 'gives a sensible error for malformed dates'
      end

      describe ':until' do
        it 'parses -u'
        it 'parses --until'
        it 'parses a date'
        it 'parses a datetime'
        it 'gives a sensible error for malformed dates'
      end

      describe ':config' do
        it 'parses -c'
        it 'parses --config'
        it 'gives a sensible error for missing files'
      end

    end
  end
end
