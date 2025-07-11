describe PubStateService do
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: total_file_size) }
  let(:subject) { PubStateService.new(identifier) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.identifier).to eq(identifier)
    end
  end

  describe '#update_for_ca_status' do
    %w[withdrawn embargoed published].each do |status|
      it "updates identifier with proper pub date for status `#{status}`" do
        subject.update_for_ca_status(status)
        expect(identifier.reload.pub_state).to eq(status)
      end
    end

    %w[in_progress processing submitted peer_review curation action_required].each do |status|
      it "updates identifier with proper pub date for status `#{status}`" do
        subject.update_for_ca_status(status)
        expect(identifier.reload.pub_state).to eq('unpublished')
      end
    end
  end
end
