module Stash
  module Wrapper
    describe Version do
      describe '#initialize' do
        attr_reader :params

        before(:each) do
          @params = {
            number: 1,
            date: Date.today,
            note: 'I am a note'
          }
        end

        it 'sets fields from arguments' do
          number = params[:number]
          date = params[:date]
          note = params[:note]
          version = Version.new(**params)
          expect(version.version_number).to eq(number)
          expect(version.date).to eq(date)
          expect(version.note).to eq(note)
        end

        it 'accepts a nil note' do
          params.delete(:note)
          version = Version.new(**params)
          expect(version.note).to be_nil

          params[:note] = nil
          version = Version.new(**params)
          expect(version.note).to be_nil
        end

        it 'accepts a DateTime as the date' do
          date = DateTime.new(2001, 2, 3, 4, 5, 6)
          params[:date] = date
          version = Version.new(**params)
          expect(version.date).to eq(date)
          xml = version.write_xml
          expect(xml).to include('<date>2001-02-03Z</date>')
        end

        it 'accepts a Time as the date' do
          date = Time.new(2001, 2, 3, 4, 5, 6)
          params[:date] = date
          version = Version.new(**params)
          expect(version.date).to eq(date)
          xml = version.write_xml
          expect(xml).to include('<date>2001-02-03Z</date>')
        end

        it 'rejects a nil number' do
          params.delete(:number)
          expect { Version.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-integer number' do
          params[:number] = 1.1
          expect { Version.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-numeric number' do
          params[:number] = '1'
          expect { Version.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a non-date or -datetime' do
          params[:date] = '2016-06-01'
          expect { Version.new(**params) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
