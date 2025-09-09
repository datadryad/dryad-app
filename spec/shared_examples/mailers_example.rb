RSpec.shared_examples('should not send an email') do
  it 'should not send an email' do
    expect { mail }.not_to(change { ActionMailer::Base.deliveries.size })
  end
end

RSpec.shared_examples('does not send email for missing resource or user email') do
  context 'when resource is not present' do
    let(:resource) { nil }

    include_examples 'should not send an email'
  end

  context 'when user is not present' do
    before { mail.instance_variable_set(:@user, nil) }

    include_examples 'should not send an email'
  end

  context 'when user email is not present' do
    before { allow_any_instance_of(described_class).to receive(:user_email).and_return(nil) }

    include_examples 'should not send an email'
  end
end
