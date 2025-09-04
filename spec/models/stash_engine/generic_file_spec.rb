# == Schema Information
#
# Table name: stash_engine_generic_files
#
#  id                  :integer          not null, primary key
#  cloud_service       :string(191)
#  compressed_try      :integer          default(0)
#  description         :text(65535)
#  digest              :string(191)
#  digest_type         :string(8)
#  download_filename   :text(65535)
#  file_deleted_at     :datetime
#  file_state          :string(7)
#  original_filename   :text(65535)
#  original_url        :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  type                :string(191)
#  upload_content_type :text(65535)
#  upload_file_name    :text(65535)
#  upload_file_size    :bigint
#  upload_updated_at   :datetime
#  url                 :text(65535)
#  validated_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resource_id         :integer
#  storage_version_id  :integer
#
# Indexes
#
#  index_stash_engine_generic_files_on_download_filename  (download_filename)
#  index_stash_engine_generic_files_on_file_deleted_at    (file_deleted_at)
#  index_stash_engine_generic_files_on_file_state         (file_state)
#  index_stash_engine_generic_files_on_resource_id        (resource_id)
#  index_stash_engine_generic_files_on_status_code        (status_code)
#  index_stash_engine_generic_files_on_upload_file_name   (upload_file_name)
#  index_stash_engine_generic_files_on_url                (url)
#
#  id                  :integer          not null, primary key
#  cloud_service       :string(191)
#  compressed_try      :integer          default(0)
#  description         :text(65535)
#  digest              :string(191)
#  digest_type         :string(8)
#  download_filename   :text(65535)
#  file_deleted_at     :datetime
#  file_state          :string(7)
#  original_filename   :text(65535)
#  original_url        :text(65535)
#  status_code         :integer
#  timed_out           :boolean          default(FALSE)
#  type                :string(191)
#  upload_content_type :text(65535)
#  upload_file_name    :text(65535)
#  upload_file_size    :bigint
#  upload_updated_at   :datetime
#  url                 :text(65535)
#  validated_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resource_id         :integer
#  storage_version_id  :integer
##
require 'fileutils'
require 'byebug'
require 'cgi'

module StashEngine
  describe GenericFile do
    include Mocks::Salesforce

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
        Timecop.travel(Time.now.utc - 1.hour)
        @user = create(:user,
                       first_name: 'Lisa',
                       last_name: 'Muckenhaupt',
                       email: 'lmuckenhaupt@datadryad.org',
                       tenant_id: 'ucop')
        @identifier = create(:identifier)
        @resource = create(:resource, user: @user, tenant_id: 'ucop', identifier: @identifier)
        @upload = create(:generic_file,
                         resource: @resource,
                         file_state: 'created',
                         download_filename: 'foo.bar')
        Timecop.return
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
        let!(:resource) { create(:resource, created_at: 2.minutes.ago) }
        let!(:created_file) { create(:data_file, resource: resource, file_state: 'created', download_filename: 'foo.bar') }

        before(:each) do
          mock_salesforce!
          resource.current_state = 'submitted'

          create(:frictionless_report, generic_file: created_file)
          create(:sensitive_data_report, generic_file: created_file)
          @new_resource = resource.amoeba_dup
          @new_resource.save!
          @new_resource.reload
        end

        it 'does not copy frictionless report' do
          copied_file = @new_resource.reload.generic_files.last.reload

          expect(created_file.file_state).to eq('created')
          expect(copied_file.file_state).to eq('copied')

          expect(copied_file.frictionless_report.id).to eq(created_file.frictionless_report.id)
          expect(copied_file.sensitive_data_report.id).to eq(created_file.sensitive_data_report.id)
        end
      end
    end

    describe 'scopes' do
      describe 'without_deleted_files' do
        let!(:file) { create(:generic_file, file_deleted_at: nil) }
        let!(:deleted_file) { create(:generic_file, file_deleted_at: Time.current) }

        context 'without scope' do
          it 'returns all files' do
            expect(StashEngine::GenericFile.all.ids).to contain_exactly(file.id, deleted_file.id)
          end
        end

        context 'without scope applied' do
          it 'returns undeleted files only' do
            expect(StashEngine::GenericFile.without_deleted_files.ids).to contain_exactly(file.id)
          end
        end
      end
    end
  end
end
