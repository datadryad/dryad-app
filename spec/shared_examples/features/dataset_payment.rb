# For journal sponsorship
RSpec.shared_examples('sponsored user does not pay anything') do
  it 'user does not pay anything' do
    expect(page).to have_text("Payment for this submission is sponsored by #{payer_name}")
    expect(page).to have_button('submit_button')
    expect(page).not_to have_button('Pay')
  end
end

RSpec.shared_examples('sponsored user must pay') do |size, amount|
  it 'user must pay' do
    expect(page).to have_text("Payment for this submission is sponsored by #{payer_name}")
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_content(
      "Since the dataset size has increased to #{size}, submitting this new version will come with an additional charge of $#{amount}."
    )
    expect(page).to have_css('button', exact_text: 'Pay & submit for publication')
    expect(page).not_to have_css('button', exact_text: 'Submit for publication')
  end
end

RSpec.shared_examples('logs sponsored LDF value') do |amount|
  it 'logs sponsored ldf value' do
    click_button 'Submit'

    expect(page).to have_text('Your dataset with the DOI', wait: 10)
    expect(identifier.reload.latest_resource.sponsored_payment_log&.ldf).to eq(amount)
  end
end

RSpec.shared_examples('pays and logs sponsored LDF value') do |amount|
  it 'logs sponsored ldf value' do
    click_button 'Pay'
    # expect(page).to have_text('Your fee breakdown is as follows:')
    # expect(page).to have_text("-$#{amount}.00")

    click_button 'Continue to the invoice generation form'
    click_button 'Send invoice & submit data'

    expect(page).to have_text('Your dataset with the DOI', wait: 10)
    expect(identifier.reload.latest_resource.sponsored_payment_log&.ldf).to eq(amount)
  end
end

RSpec.shared_examples('no LDF sponsored payment log is created') do
  it 'no LDF sponsored payment log is created' do
    click_button 'Submit'

    expect(page).to have_text('Your dataset with the DOI', wait: 10)
    expect(identifier.reload.latest_resource.sponsored_payment_log).to be_nil
  end
end

RSpec.shared_examples('pays and no LDF sponsored payment log is created') do
  it 'no LDF sponsored payment log is created' do
    click_button 'Pay & submit for publication'
    click_button 'Continue to the invoice generation form'
    click_button 'Send invoice & submit data'

    expect(page).to have_text('Your dataset with the DOI', wait: 10)
    expect(identifier.reload.latest_resource.sponsored_payment_log).to be_nil
  end
end

# For individual users
RSpec.shared_examples('individual user does not pay anything') do
  it 'user does not pay anything' do
    expect(page).to have_button('Submit for')
    expect(page).not_to have_button('Pay & submit')
  end
end

RSpec.shared_examples('individual user must pay') do |size, amount|
  it 'user must pay' do
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_content(
      "Since the dataset size has increased to #{size}, submitting this new version will come with an additional charge of $#{amount}."
    )
    expect(page).not_to have_button('Submit for')
    expect(page).to have_button('Pay & submit')
  end
end

RSpec.shared_examples('ppr - individual user must pay') do |size, amount|
  it 'user must pay' do
    total = "#{amount.to_i + 50}.00"
    expect(page).to have_content(
      "This #{size} dataset has a Data Publishing Charge of $#{total}, requiring payment of $#{amount} minus the Private for Peer Review Fee"
    )
    expect(page).not_to have_button('Submit for')
    expect(page).to have_button('Pay & submit')
  end
end
