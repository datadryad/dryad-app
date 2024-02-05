# == Schema Information
#
# Table name: stash_engine_zenodo_copies
#
#  id            :integer          not null, primary key
#  conceptrecid  :string(191)
#  copy_type     :string           default("data")
#  error_info    :text(16777215)
#  note          :text(65535)
#  retries       :integer          default(0)
#  software_doi  :string(191)
#  state         :string           default("enqueued")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  deposition_id :integer
#  identifier_id :integer
#  resource_id   :integer
#
# Indexes
#
#  index_stash_engine_zenodo_copies_on_conceptrecid   (conceptrecid)
#  index_stash_engine_zenodo_copies_on_copy_type      (copy_type)
#  index_stash_engine_zenodo_copies_on_deposition_id  (deposition_id)
#  index_stash_engine_zenodo_copies_on_identifier_id  (identifier_id)
#  index_stash_engine_zenodo_copies_on_note           (note)
#  index_stash_engine_zenodo_copies_on_resource_id    (resource_id)
#  index_stash_engine_zenodo_copies_on_retries        (retries)
#  index_stash_engine_zenodo_copies_on_software_doi   (software_doi)
#  index_stash_engine_zenodo_copies_on_state          (state)
#
module StashEngine
  describe ZenodoCopy, type: :model do

    before(:each) do
      # Mock all the mailers fired by callbacks because these tests don't load everything we need
      @identifier = create(:identifier)
      @resource1 = create(:resource, identifier_id: @identifier.id)
      @resource2 = create(:resource, identifier_id: @identifier.id)

      @zc_soft1 = create(:zenodo_copy, identifier_id: @identifier.id, resource_id: @resource1.id, copy_type: 'software',
                                       state: 'finished')
      @soft_file1 = create(:software_file, resource_id: @resource1.id)

      @zc_soft2 = create(:zenodo_copy, identifier_id: @identifier.id, resource_id: @resource2.id, copy_type: 'software',
                                       state: 'finished')
      @soft_file2 = create(:software_file, resource_id: @resource2.id)

      @zc_supp1 = create(:zenodo_copy, identifier_id: @identifier.id, resource_id: @resource1.id, copy_type: 'supp',
                                       state: 'finished')
      @supp_file1 = create(:supp_file, resource_id: @resource1.id)

      @zc_supp2 = create(:zenodo_copy, identifier_id: @identifier.id, resource_id: @resource2.id, copy_type: 'supp',
                                       state: 'finished')
      @supp_file2 = create(:supp_file, resource_id: @resource2.id)
    end

    describe 'self.last_copy_with_software(identifier_id:)' do
      it 'returns the latest software copy when everything is finished and has files' do
        expect(ZenodoCopy.last_copy_with_software(identifier_id: @identifier.id)).to eq(@zc_soft2)
      end

      it "returns the first software copy when the second isn't finished yet" do
        @zc_soft2.update(software_doi: nil)
        expect(ZenodoCopy.last_copy_with_software(identifier_id: @identifier.id)).to eq(@zc_soft1)
      end

      it "returns the first software copy when the second doesn't have files" do
        @soft_file2.update(file_state: 'deleted')
        expect(ZenodoCopy.last_copy_with_software(identifier_id: @identifier.id)).to eq(@zc_soft1)
      end

      it "doesn't return anything if no files" do
        @resource1.software_files.each(&:destroy)
        @resource2.software_files.each(&:destroy)
        expect(ZenodoCopy.last_copy_with_software(identifier_id: @identifier.id)).to be_nil
      end

      it "doesn't return anything if all unfinished" do
        @zc_soft1.update(software_doi: nil)
        @zc_soft2.update(software_doi: nil)
        expect(ZenodoCopy.last_copy_with_software(identifier_id: @identifier.id)).to be_nil
      end
    end

    describe 'self.last_copy_with_supp(identifier_id:)' do
      it 'returns the latest supplemental copy when everything is finished and has files' do
        expect(ZenodoCopy.last_copy_with_supp(identifier_id: @identifier.id)).to eq(@zc_supp2)
      end

      it "returns the first supplemental copy when the second isn't finished yet" do
        @zc_supp2.update(software_doi: nil)
        expect(ZenodoCopy.last_copy_with_supp(identifier_id: @identifier.id)).to eq(@zc_supp1)
      end

      it "returns the first supplemental copy when the second doesn't have files" do
        @supp_file2.update(file_state: 'deleted')
        expect(ZenodoCopy.last_copy_with_supp(identifier_id: @identifier.id)).to eq(@zc_supp1)
      end

      it "doesn't return anything if no files" do
        @resource1.supp_files.each(&:destroy)
        @resource2.supp_files.each(&:destroy)
        expect(ZenodoCopy.last_copy_with_supp(identifier_id: @identifier.id)).to be_nil
      end

      it "doesn't return anything if all unfinished" do
        @zc_supp1.update(software_doi: nil)
        @zc_supp2.update(software_doi: nil)
        expect(ZenodoCopy.last_copy_with_supp(identifier_id: @identifier.id)).to be_nil
      end
    end
  end
end
