RSpec.shared_examples('calling FeeCalculatorService') do |type|
  it "calculates with #{type} type" do
    expect(FeeCalculatorService).to receive_message_chain(:new, :calculate).with(type).with(options, resource: resource).and_return({})
    described_class.new(resource).calculate(options)
  end
end

RSpec.shared_examples('it has 2 TB max limit based on options') do |extra_options = {}|
  context 'with storage_size over 2 TB limit' do
    let(:options) { extra_options.merge({ storage_size: 2_000_000_000_001 }) }

    it_behaves_like 'it raises out of range error'
  end
end

RSpec.shared_examples('it has 2 TB max limit') do
  context 'with storage_size over 2 TB limit' do
    let(:new_files_size) { 2_000_000_000_001 }

    it_behaves_like 'it raises out of range error'
  end
end

RSpec.shared_examples('it raises out of range error') do
  it 'raises an error' do
    expect { subject }.to raise_error(ActionController::BadRequest, OUT_OF_RANGE_MESSAGE)
  end
end
