module PaymentsHelper
  # For journal sponsorship
  def sponsored_no_fee
    expect(page).to have_text("Payment for this submission is sponsored by #{payer_name}")
    expect(page).to have_button('submit_button')
    expect(page).not_to have_button('Pay')
  end

  def sponsored_with_fee(size, amount)
    expect(page).to have_text("Payment for this submission is sponsored by #{payer_name}")
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_content(
      "Since the dataset size has increased to #{size}, submitting this new version will come with an additional charge of $#{amount}.",
      wait: 5
    )
    expect(page).to have_css('button', exact_text: 'Pay & submit for publication')
    expect(page).not_to have_css('button', exact_text: 'Submit for publication')
  end

  def logs_ldf(amount)
    click_button 'Submit'

    expect(page).to have_text('Your dataset with the DOI')
    expect(identifier.reload.latest_resource.sponsored_payment_log&.ldf).to eq(amount)
  end

  def pays_and_logs_ldf(amount)
    click_button 'Pay'

    # expect(page).to have_text('Your fee breakdown is as follows:')
    # expect(page).to have_text("-$#{amount}.00")

    click_button 'Continue to the invoice generation form'
    click_button 'Send invoice & submit data'

    expect(page).to have_text('Your dataset with the DOI')
    expect(identifier.reload.latest_resource.sponsored_payment_log&.ldf).to eq(amount)
  end

  def no_ldf
    click_button 'Submit'

    expect(page).to have_text('Your dataset with the DOI')
    expect(identifier.reload.latest_resource.sponsored_payment_log).to be_nil
  end

  def pays_and_no_ldf
    click_button 'Pay & submit for publication'
    click_button 'Continue to the invoice generation form'
    click_button 'Send invoice & submit data'

    expect(page).to have_text('Your dataset with the DOI')
    expect(identifier.reload.latest_resource.sponsored_payment_log).to be_nil
  end

  # For individual users
  def unsponsored_no_fee
    expect(page).to have_button('Submit for')
    expect(page).not_to have_button('Pay & submit')
  end

  def unsponsored_with_fee(size, amount)
    expect(page).to have_content('This dataset has been previously submitted')
    expect(page).to have_content(
      "Since the dataset size has increased to #{size}, submitting this new version will come with an additional charge of $#{amount}.",
      wait: 5
    )
    expect(page).not_to have_button('Submit for')
    expect(page).to have_button('Pay & submit')
  end

  def unsponsored_ppr_paid(size, amount)
    total = "#{amount.to_i + 50}.00"
    expect(page).to have_content(
      "This #{size} dataset has a Data Publishing Charge of $#{total}, requiring payment of $#{amount} minus the Private for Peer Review Fee"
    )
    expect(page).not_to have_button('Submit for')
    expect(page).to have_button('Pay & submit')
  end
end
