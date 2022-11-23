module Stash
  module Wrapper
    describe Embargo do
      describe '#initialize' do

        attr_reader :params

        before(:each) do
          @params = {
            type: EmbargoType::DOWNLOAD,
            period: 'a year and a day',
            start_date: Date.new(2015, 1, 1),
            end_date: Date.new(2016, 1, 1)
          }
        end

        it 'sets values from parameters' do
          type = params[:type]
          period = params[:period]
          start_date = params[:start_date]
          end_date = params[:end_date]
          embargo = Embargo.new(**params)
          expect(embargo.type).to eq(type)
          expect(embargo.period).to eq(period)
          expect(embargo.start_date).to eq(start_date)
          expect(embargo.end_date).to eq(end_date)
        end

        it 'rejects a nil type' do
          params[:type] = nil
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a string type' do
          params[:type] = 'download'
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil period' do
          params[:period] = nil
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects an empty period' do
          params[:period] = ''
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a blank period' do
          params[:period] = ' '
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil start date' do
          params[:start_date] = nil
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a string start date' do
          params[:start_date] = '2015-01-01'
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil end date' do
          params[:end_date] = nil
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a string end date' do
          params[:end_date] = '2016-01-01'
          expect { Embargo.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects an invalid date range' do
          params[:start_date] = Date.new(2016, 1, 1)
          params[:end_date] = Date.new(2015, 12, 31)
          expect { Embargo.new(**params) }.to raise_error(RangeError)
        end
      end

      describe 'none' do
        it "returns a no-embargo #{Embargo}" do
          embargo = Embargo.none
          expect(embargo).to be_an(Embargo)
          expect(embargo.type).to eq(EmbargoType::NONE)
          expect(embargo.period).to eq('none')
          today = Date.today
          expect(embargo.start_date).to eq(today)
          expect(embargo.end_date).to eq(today)
        end
      end
    end
  end
end
