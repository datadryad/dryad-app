require_relative '../../../../lib/stash/compressed/zip_info'
require 'byebug'

require 'spec/support/helpers/http_range_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Compressed
    RSpec.describe ZipInfo do

      include HttpRangeHelper

      # also tests #get_size
      describe '#size' do
        it 'returns the size of the zip file' do
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: 1234)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect(zi.size).to eq(1234)
        end

        it 'raises an error if 400+ status code returned' do
          stub_request(:get, 'https://example.com/zipfile.zip')
            .with(headers: { 'Range' => 'bytes=0-0' })
            .to_return(status: 404, body: 'Not found')

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect { zi.size }.to raise_error(Stash::Compressed::InvalidResponse)
        end

        it 'raises an error if Content-Range header is missing' do
          stub_request(:get, 'https://example.com/zipfile.zip')
            .with(headers: { 'Range' => 'bytes=0-0' })
            .to_return(status: 200, body: '')

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect { zi.size }.to raise_error(Stash::Compressed::InvalidResponse)
        end

        it 'caches the size' do
          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          zi.instance_variable_set(:@size, 8474)
          expect(zi.size).to eq(8474)
        end
      end

      describe '#eocd_record32' do
        it 'obtains the EOCD record' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip') # small zip file to test
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 69_305, r_end: 134_840,
                             body: file_string[69_305..134_840], file_size: file_string.size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          rec32 = zi.eocd_record32
          expect(rec32.length).to eq(22)
          expect(rec32[0..3]).to eq("\x50\x4b\x05\x06")
        end

        it 'raises an error if the EOCD record is not found' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip') # small zip file to test
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_string.size)

          # this will not include the EOCD record
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 69_305, r_end: 134_840,
                             body: file_string[69_205..134_740], file_size: file_string.size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect { zi.eocd_record32 }.to raise_error(Stash::Compressed::ZipError)
        end
      end

      describe '#eocd_record64' do
        it 'obtains the EOCD64 record' do
          file_size = 5_723_622_354
          eocd32 = File.binread('spec/fixtures/zipfiles/zip64_eocd32_request.bin')
          eocd64 = File.binread('spec/fixtures/zipfiles/zip64_eocd64_request.bin')

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_818, r_end: 5_723_622_353,
                             body: eocd32, file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_796, r_end: 5_723_622_331,
                             body: eocd64, file_size: file_size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          rec64 = zi.eocd_record64
          expect(rec64.length).to eq(76)
          expect(rec64[0..3]).to eq("\x50\x4b\x06\x06")
          expect(rec64[56..57]).to eq('PK')
        end

        it 'raises an error if EOCD64 record not found' do
          file_size = 5_723_622_354
          eocd32 = File.binread('spec/fixtures/zipfiles/zip64_eocd32_request.bin')
          eocd64 = File.binread('spec/fixtures/zipfiles/zip64_eocd64_request.bin')

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_818, r_end: 5_723_622_353,
                             body: eocd32, file_size: file_size)

          # this will not include the EOCD64 record
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_796, r_end: 5_723_622_331,
                             body: eocd64[0..63_000], file_size: file_size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect { zi.eocd_record64 }.to raise_error(Stash::Compressed::ZipError)
        end
      end

      describe '#zip64?' do
        it 'returns false if the zip file is zip32' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip') # small zip file to test
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 69_305, r_end: 134_840,
                             body: file_string[69_305..134_840], file_size: file_string.size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect(zi.zip64?).to be false
        end

        it 'returns true if the zip file is zip64' do
          file_size = 5_723_622_354
          eocd32 = File.binread('spec/fixtures/zipfiles/zip64_eocd32_request.bin')
          # eocd64 = File.open('spec/fixtures/zipfiles/zip64_eocd64_request.bin', 'rb').read

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_818, r_end: 5_723_622_353,
                             body: eocd32, file_size: file_size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          expect(zi.zip64?).to be true
        end
      end

      describe '#central_directory' do
        it 'returns the zip32 central directory' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip') # small zip file to test
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 69_305, r_end: 134_840,
                             body: file_string[69_305..134_840], file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 134_134, r_end: 134_818,
                             body: file_string[134_134..134_818], file_size: file_string.size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          my_cd = zi.central_directory
          expect(my_cd[0..3]).to eq("\x50\x4b\x01\x02")
          expect(my_cd.length).to eq(685)
        end

        it 'returns the zip64 central directory' do
          file_size = 5_723_622_354
          eocd32 = File.binread('spec/fixtures/zipfiles/zip64_eocd32_request.bin')
          eocd64 = File.binread('spec/fixtures/zipfiles/zip64_eocd64_request.bin')
          central_dir = File.binread('spec/fixtures/zipfiles/zip64_cd_request.bin')

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_818, r_end: 5_723_622_353,
                             body: eocd32, file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_796, r_end: 5_723_622_331,
                             body: eocd64, file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_621_497, r_end: 5_723_622_255,
                             body: central_dir, file_size: file_size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          my_cd = zi.central_directory
          expect(my_cd[0..3]).to eq("\x50\x4b\x01\x02")
          expect(my_cd.length).to eq(759)
        end
      end

      describe '#file_entries' do
        it 'gives correct file entries for zip32' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip') # small zip file to test
          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 69_305, r_end: 134_840,
                             body: file_string[69_305..134_840], file_size: file_string.size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 134_134, r_end: 134_818,
                             body: file_string[134_134..134_818], file_size: file_string.size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          fe = zi.file_entries
          expect(fe.length).to eq(6)
          expect(fe.first[:file_name]).to eq('Screen Shot 2022-12-09 at 12.17.31 PM.png')
          expect(fe.first[:compressed_size]).to eq(56_508)
          expect(fe.first[:uncompressed_size]).to eq(68_742)
          expect(fe[4][:file_name]).to eq('README.txt')
          expect(fe[4][:compressed_size]).to eq(15)
          expect(fe[4][:uncompressed_size]).to eq(13)
        end

        it 'gives correct file entries for zip64' do
          file_size = 5_723_622_354
          eocd32 = File.binread('spec/fixtures/zipfiles/zip64_eocd32_request.bin')
          eocd64 = File.binread('spec/fixtures/zipfiles/zip64_eocd64_request.bin')
          central_dir = File.binread('spec/fixtures/zipfiles/zip64_cd_request.bin')

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 0, r_end: 0, body: '', file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_818, r_end: 5_723_622_353,
                             body: eocd32, file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_556_796, r_end: 5_723_622_331,
                             body: eocd64, file_size: file_size)

          stub_range_request(url: 'https://example.com/zipfile.zip', r_start: 5_723_621_497, r_end: 5_723_622_255,
                             body: central_dir, file_size: file_size)

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          fe = zi.file_entries
          expect(fe[1][:file_name]).to eq('Fig_S9_S10_SwitchBack_Microfluidics/Fig_S10_Ind43_SwitchBack_strategy_iii/' \
                                          '1stPhase_43Ind_BF_mVenus_mRFP_10min.tif')
          expect(fe[1][:compressed_size]).to eq(616_580_012)
          expect(fe[1][:uncompressed_size]).to eq(962_225_153)
          expect(fe[4][:file_name]).to eq('Fig_S9_S10_SwitchBack_Microfluidics/Fig_S9-S10_SwitchBack_Microfluidics.xlsx')
          expect(fe[4][:compressed_size]).to eq(91_823)
          expect(fe[4][:uncompressed_size]).to eq(94_267)
        end
      end

      describe '#fallback_file_entries1' do
        it 'gives correct file entries for zip32' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip')
          stub_request(:get, 'https://example.com/zipfile.zip')
            .with(headers: { 'Host' => 'example.com' })
            .to_return(status: 200, body: file_string,
                       headers: { 'Content-Type' => 'application/zip' })

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          fe = zi.fallback_file_entries1
          expect(fe.first[:file_name]).to eq('Screen Shot 2022-12-09 at 12.17.31 PM.png')
          expect(fe.first[:uncompressed_size]).to eq(68_742)
        end
      end

      describe '#fallback_file_entries2' do
        # there isn't a good way to mock this since it's outside of rails network libraries w/ curl
        # but tested manually
        xit 'gives correct file entries for zip32' do
          file_string = File.binread('spec/fixtures/zipfiles/test_zip.zip')
          stub_request(:get, 'https://example.com/zipfile.zip')
            .with(headers: { 'Host' => 'example.com' })
            .to_return(status: 200, body: file_string,
                       headers: { 'Content-Type' => 'application/zip' })

          zi = Stash::Compressed::ZipInfo.new(presigned_url: 'https://example.com/zipfile.zip')
          fe = zi.fallback_file_entries2
          expect(fe.first[:file_name]).to eq('Screen Shot 2022-12-09 at 12.17.31 PM.png')
          expect(fe.first[:uncompressed_size]).to eq(68_742)
        end
      end
    end
  end
end
