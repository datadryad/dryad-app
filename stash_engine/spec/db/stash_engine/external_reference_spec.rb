require 'db_spec_helper'

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

      it 'requires an identifier' do
        external_reference = StashEngine::ExternalReference.new(identifier: nil, source: 'nuccore', value: 'TEST')
        expect(external_reference.valid?).to eql(false)
      end

      it 'requires a value' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'nuccore', value: nil)
        expect(external_reference.valid?).to eql(false)
      end

      it 'requires that the source value belong to the enum list' do
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'testing', value: 'TEST')
        expect(external_reference.valid?).to eql(false)
      end

      it 'requires that the source be unique for the identifier' do
        StashEngine::ExternalReference.create(identifier: @identifier, source: 'bioproject', value: 'TEST')
        external_reference = StashEngine::ExternalReference.new(identifier: @identifier, source: 'bioproject', value: 'DUPLICATE')
        expect(external_reference.valid?).to eql(false)
      end
    end

    context :associations do
      it 'gets destroyed when parent identifier is destroyed' do
        external_reference = StashEngine::ExternalReference.create(identifier: @identifier)
        @identifier.reload
        @identifier.destroy
        expect(StashEngine::ExternalReference.where(id: external_reference.id).any?).to eql(false)
      end
    end

  end
end
