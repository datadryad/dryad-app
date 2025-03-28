describe FeeCalculatorService do

  describe '#calculate' do
    context 'with institution type' do
      it 'calls InstitutionService' do
        expect(FeeCalculator::InstitutionService).to receive_message_chain(:new, :call).with({}, resource: nil).with(no_args)
        described_class.new('institution').calculate({})
      end
    end

    context 'with publisher type' do
      it 'calls PublisherService' do
        expect(FeeCalculator::PublisherService).to receive_message_chain(:new, :call).with({ option: 'option' }, resource: nil).with(no_args)
        described_class.new('publisher').calculate({ option: 'option' })
      end
    end

    context 'with individual type' do
      it 'calls IndividualService' do
        expect(FeeCalculator::IndividualService).to receive_message_chain(:new, :call).with({}, resource: nil).with(no_args)
        described_class.new('individual').calculate({})
      end
    end

    context 'with invalid type' do
      it 'it raises an error' do
        expect { described_class.new('something').calculate({}) }.to raise_error(NotImplementedError, 'Invalid calculator type')
      end
    end
  end
end
