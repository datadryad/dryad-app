module Stash
  module Wrapper
    describe Inventory do
      describe '#initialize' do
        attr_reader :params
        before(:each) do
          @params = {
            files: [
              StashFile.new(pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'),
              StashFile.new(pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'),
              StashFile.new(pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data')
            ]
          }
        end

        it 'sets the file list' do
          files = params[:files]
          inv = Inventory.new(**params)
          expect(inv.files).to eq(files)
        end

        it 'sets the file count' do
          files = params[:files]
          inv = Inventory.new(**params)
          expect(inv.num_files).to eq(files.size)
        end

        it 'accepts an empty list' do
          params[:files] = []
          inv = Inventory.new(**params)
          expect(inv.files).to eq([])
          expect(inv.num_files).to eq(0)
        end

        it 'rejects single files' do
          params[:files] = params[:files][0]
          expect { Inventory.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects strings' do
          params[:files] = 'HSRC_MasterSampleII.dat'
          expect { Inventory.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects File objects' do
          File.open('spec/data/wrapper/wrapper-2-payload.xml') do |f|
            params[:files] = f
            expect { Inventory.new(**params) }.to raise_error(ArgumentError)
          end
        end

        it 'rejects arrays of strings' do
          params[:files] = params[:files].map(&:pathname)
          expect { Inventory.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects arrays of File objects' do
          files = [
            File.new('spec/data/wrapper/wrapper-1.xml'),
            File.new('spec/data/wrapper/wrapper-1.xml')
          ]
          begin
            params[:files] = files
            expect { Inventory.new(**params) }.to raise_error(ArgumentError)
          ensure
            files.each(&:close)
          end
        end

      end
    end
  end
end
