RSpec.shared_examples('user does not pay anything') do
  it 'user does not pay anything' do
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
    expect(page).to have_css('button', exact_text: 'Submit for publication')
  end
end

RSpec.shared_examples('user must pay') do |size, amount|
  it 'user must pay' do
    expect(page).to have_text("Payment for this submission is sponsored by #{journal.title}")
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_content(
      "Since the dataset size has increased to #{size}, submitting this new version will come with an additional charge of $#{amount}."
    )
    expect(page).to have_css('button', exact_text: 'Pay & Submit for publication')
  end
end

RSpec.shared_examples('logs sponsored LDF value') do |amount|
  it 'logs sponsored ldf value' do
    click_button 'Submit for publication'

    sleep 1
    expect(identifier.reload.latest_resource.sponsored_payment_log&.ldf).to eq(amount)
  end
end

RSpec.shared_examples('no LDF sponsored payment log is created') do
  it 'logs sponsored ldf value' do
    click_button 'Submit for publication'

    expect(identifier.reload.latest_resource.sponsored_payment_log).to be_nil
  end
end
