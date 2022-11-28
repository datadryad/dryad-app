module Stash
  module Wrapper
    describe StashAdministrative do

      attr_reader :params

      before(:each) do
        @params = {
          version: Version.new(number: 1, date: Date.new(2013, 8, 18), note: 'Sample wrapped Datacite document'),
          license: License::CC_BY,
          inventory: Inventory.new(
            files: [
              StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain')
            ]
          )
        }
      end

      describe :initialize do

        describe :version do
          it 'requires a version' do
            params.delete(:version)
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end

          it 'requires a valid version' do
            params[:version] = 1
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)

            params[:version] = '1'
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end
        end

        describe :license do
          it 'requires a license' do
            params.delete(:license)
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end

          it 'requires a valid license' do
            params[:license] = 'CC-BY'
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end
        end

        describe :embargo do
          it 'defaults to no embargo' do
            admin = StashAdministrative.new(**params)
            embargo = admin.embargo
            expect(embargo).to be_an(Embargo)
            expect(embargo.type).to eq(EmbargoType::NONE)
            expect(embargo.period).to eq('none')
            today = Date.today
            expect(embargo.start_date).to eq(today)
            expect(embargo.end_date).to eq(today)
          end

          it 'allows an explicit embargo' do
            embargo = Embargo.new(type: EmbargoType::DOWNLOAD,
                                  period: 'a year and a day',
                                  start_date: Date.new(2015, 1, 1),
                                  end_date: Date.new(2016, 1, 1))
            params[:embargo] = embargo
            admin = StashAdministrative.new(**params)
            expect(admin.embargo).to be(embargo)
          end

          it 'requires embargo to be an embargo' do
            params[:embargo] = '2017-05-15'
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end
        end

        describe :inventory do
          it 'accepts an inventory' do
            inventory = params[:inventory]
            admin = StashAdministrative.new(**params)
            expect(admin.inventory).to be(inventory)
          end

          it 'allows a nil inventory' do
            params.delete(:inventory)
            admin = StashAdministrative.new(**params)
            expect(admin.inventory).to be(nil)
          end

          it 'requires inventory to be an inventory' do
            params[:inventory] = [{ pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain' }]
            expect { StashAdministrative.new(**params) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
