RSpec.shared_examples('calling FeeCalculatorService') do |type|
  it "calculates with #{type} type" do
    expect(FeeCalculatorService).to receive_message_chain(:new, :calculate).with(type).with(options, resource: resource).and_return({})
    described_class.new(resource).calculate(options)
  end
end
