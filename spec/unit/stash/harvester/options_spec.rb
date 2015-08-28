require 'stash/harvester/options'

module Stash
  module Harvester
    describe Options do

      it 'can provide a usage message'
      it 'provides sensible error reporting'

      describe ':help' do
        it 'parses -h'
        it 'parses --help'
      end

      describe ':version' do
        it 'parses -v'
        it 'parses --version'
      end

      describe ':from' do
        it 'parses -f'
        it 'parses --from'
        it 'gives a sensible error for malformed dates'
      end

      describe ':until' do
        it 'parses -u'
        it 'parses --until'
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
