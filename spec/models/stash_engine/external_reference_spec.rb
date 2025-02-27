# == Schema Information
#
# Table name: stash_engine_external_references
#
#  id            :integer          not null, primary key
#  source        :string(191)
#  value         :text(4294967295)
#  created_at    :datetime
#  updated_at    :datetime
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_external_references_on_identifier_id  (identifier_id)
#  index_stash_engine_external_references_on_source         (source)
#
module StashEngine
  describe ExternalReference do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
    end

    context :new do
      it 'defaults source to :nuccore' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier)
        expect(external_reference.source).to eql('nuccore')
      end

      it 'source does not allow nil' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: nil)
        expect(external_reference.valid?).to be_falsey
        expect(external_reference.errors.messages[:source]).to eq([' is not a valid source'])
      end

      it 'requires an identifier' do
        external_reference = StashEngine::ExternalReference.new(identifier: nil, source: 'nuccore', value: 'TEST')
        expect(external_reference.valid?).to be_falsey
      end

      it 'requires a value' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'nuccore', value: nil)
        expect(external_reference.valid?).to be_falsey
      end

      it 'requires that the source value belong to the enum list' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'testing', value: 'TEST')
        expect(external_reference.valid?).to be_falsey
        expect(external_reference.errors.messages[:source]).to eq(['testing is not a valid source'])
      end

      it 'requires that the source be unique for the identifier' do
        StashEngine::ExternalReference.create(identifier: @identifier, source: 'bioproject', value: 'TEST')
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'bioproject', value: 'DUPLICATE')
        expect(external_reference.valid?).to be_falsey
      end
    end

    context :associations do
      it 'gets destroyed when parent identifier is destroyed' do
        external_reference = StashEngine::ExternalReference.create(identifier: @identifier)
        @identifier.reload
        @identifier.destroy
        expect(StashEngine::ExternalReference.where(id: external_reference.id).any?).to be_falsey
      end
    end

  end
end
