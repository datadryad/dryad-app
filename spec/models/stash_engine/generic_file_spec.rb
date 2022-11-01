require 'fileutils'
require 'byebug'
require 'cgi'

module StashEngine
  describe GenericFile do

    # this is just to be sure that Single Table Inheritance is set up correctly
    describe 'works for subclasses' do
      before(:each) do
        @resource = create(:resource)
        @data_f = create(:data_file, resource_id: @resource.id)
        @soft_f = create(:software_file, resource_id: @resource.id)
        @supp_f = create(:supp_file, resource_id: @resource.id)
      end

      it 'gets all different types of files for generic files' do
        expect(@resource.generic_files.count).to eq(3)
      end

      it 'only returns one result for specific type of file' do
        expect(@resource.data_files.count).to eq(1)
      end
    end

    describe :simple_methods do
      before(:each) do
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@ucop.edu',
                       tenant_id: 'ucop')

        @identifier = create(:identifier)
        @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @upload = create(:generic_file,
                         resource: @resource,
                         file_state: 'created',
                         upload_file_name: 'foo.bar')
      end

      describe :error_message do
        it 'returns the empty string for uploads with no URL' do
          expect(@upload.error_message).to eq('')
        end

        it 'returns the empty string for uploads with status 200' do
          @upload.url = 'http://example.org/foo.bar'
          @upload.status_code = 200
          expect(@upload.error_message).to eq('')
        end

        it 'returns a non-empty message for all other states' do
          @upload.url = 'http://example.org/foo.bar'
          (100..599).each do |status|
            next if status == 200

            @upload.status_code = status
            message = @upload.error_message
            expect(message).not_to be_nil
            expect(message.strip).to eq(message)
            expect(message).not_to be_empty
          end
        end
      end

      describe :digests do
        it 'identifies item without digest' do
          expect(@upload.digest?).to be false
        end

        it 'identifies item without digest type' do
          @upload.update(digest: '12345')
          expect(@upload.digest?).to be false
        end

        it 'identifies item without digest' do
          @upload.update(digest_type: 'md5')
          expect(@upload.digest?).to be false
        end

        it 'identifies item with complete digest info' do
          @upload.update(digest_type: 'md5', digest: '12345')
          expect(@upload.digest?).to be true
        end
      end

      describe :sanitize_file_name do
        # Ensure that non-printable ACII control characters < 32 are sanitized
        it 'removes ASCII Control characters (0-31)' do
          32.times do |i|
            expect(StashEngine::GenericFile.sanitize_file_name("#{i.chr}abc123")).to eql('abc123')
            expect(StashEngine::GenericFile.sanitize_file_name("abc123#{i.chr}")).to eql('abc123')

            # Zaru replaces characters 9-13 with a space
            if (9..13).cover?(i)
              expect(StashEngine::GenericFile.sanitize_file_name("abc#{i.chr}123")).to eql('abc_123')
            else
              expect(StashEngine::GenericFile.sanitize_file_name("abc#{i.chr}123")).to eql('abc123')
            end
          end
        end

        it 'removes ASCII Delete character (127)' do
          expect(StashEngine::GenericFile.sanitize_file_name("#{127.chr}abc123")).to eql('abc123')
          expect(StashEngine::GenericFile.sanitize_file_name("abc123#{127.chr}")).to eql('abc123')
          expect(StashEngine::GenericFile.sanitize_file_name("abc#{127.chr}123")).to eql('abc123')
        end

        it 'replaces spaces with underscores' do
          expect(StashEngine::GenericFile.sanitize_file_name('abc 123')).to eql('abc_123')
          expect(StashEngine::GenericFile.sanitize_file_name('abc  123')).to eql('abc_123')
        end

        it 'removes trailing and leading spaces' do
          expect(StashEngine::GenericFile.sanitize_file_name('  abc123')).to eql('abc123')
          expect(StashEngine::GenericFile.sanitize_file_name('abc123  ')).to eql('abc123')
        end

        %w[| / \\ : ; " ' < > , ?].each do |chr|
          it "removes #{chr}" do
            expect(StashEngine::GenericFile.sanitize_file_name("#{chr}abc123")).to eql('abc123')
            expect(StashEngine::GenericFile.sanitize_file_name("abc#{chr}123")).to eql('abc123')
            expect(StashEngine::GenericFile.sanitize_file_name("abc123#{chr}")).to eql('abc123')
          end
        end

        it 'does not remove foreign characters' do
          expect(StashEngine::GenericFile.sanitize_file_name('abc𠝹Ѭμ123')).to eql('abc𠝹Ѭμ123')
        end

        it 'does not remove emoji characters' do
          expect(StashEngine::GenericFile.sanitize_file_name('abc😂123')).to eql('abc😂123')
        end

      end

      describe 'amoeba duplication' do
        before(:each) do
          @report = create(:frictionless_report, generic_file: @upload)
          @resource2 = @resource.amoeba_dup
          @resource2.save
          @upload2 = GenericFile.last
        end

        it 'copies frictionless report' do
          expect(@upload2.frictionless_report.id).not_to eq(@upload.frictionless_report.id)
          expect(@upload2.frictionless_report.report).to eq(@upload.frictionless_report.report)
        end
      end
    end
  end
end
