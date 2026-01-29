describe TargetStatusService do

  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:curator) { create(:user, role: 'curator') }
  let(:subject) { TargetStatusService.new(resource) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.resource).to eq(resource)
    end
  end

  describe '#curator_override?' do
    let(:subject) { TargetStatusService.new(resource).curator_override? }

    context 'returns false' do
      it { is_expected.to be_falsey }
    end

    context 'returns false when curator has not set ppr' do
      before do
        create(:curation_activity, :peer_review, resource: resource, user: resource.submitter)
      end
      it { is_expected.to be_falsey }
    end

    context 'returns true when curator has set ppr' do
      before do
        create(:curation_activity, :peer_review, resource: resource, user: curator)
      end
      it { is_expected.to be_truthy }
    end
  end

  describe '#allow_ppr?' do
    let(:subject) { TargetStatusService.new(resource).allow_ppr? }

    context 'returns true when PPR is allowed' do
      it { is_expected.to be_truthy }
    end

    context 'returns false when identifier is published' do
      before { identifier.update(pub_state: 'published') }
      it { is_expected.to be_falsey }
    end

    context 'returns false when manuscript is accepted' do
      before do
        man = create(:manuscript, identifier: identifier)
        create(:resource_publication, resource: resource, manuscript_number: man.manuscript_number, publication_issn: man.journal.single_issn)
      end
      it { is_expected.to be_falsey }
    end

    context 'returns false when publication is published' do
      before { create(:related_identifier, :publication_doi, resource: resource) }
      it { is_expected.to be_falsey }
    end

    context 'returns false when previously curated' do
      before do
        create(:curation_activity, :curation, resource: resource, user: curator)
        create(:curation_activity, :action_required, resource: resource, user: curator)
      end
      it { is_expected.to be_falsey }
    end

    context 'returns true when curation overridden by curator' do
      before do
        create(:curation_activity, :curation, resource: resource, user: curator)
        create(:curation_activity, :action_required, resource: resource, user: curator)
        create(:curation_activity, :peer_review, resource: resource, user: curator)
      end
      it { is_expected.to be_truthy }
    end
  end
end
