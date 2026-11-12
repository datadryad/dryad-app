class PaymentCommitmentService

  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
  # reload!; PaymentCommitmentService.generate(84, 3, start_date: '2025-08-01'.to_date, asf:10_000, dpc:3000, ldf: 5000, asf_prepaid: 10_000)

  def self.generate(
    config_id,
    commitment_years,
    asf:, dpc:, ldf:, asf_prepaid:, start_date: Time.current,
    include_year_0: nil
  )
    start_year = start_date.year
    discounts = COMMITMENT_DISCOUNTS[commitment_years.to_s]
    # if include_year_0 is not specified
    # set it to true if start_date is after July 1st of the current year
    include_year_0 = start_date > Date.new(start_date.year, 7, 1) if include_year_0.nil?
    years_to_add, aux = if include_year_0
                          [0..commitment_years, 0]
                        else
                          [1..commitment_years, 1]
                        end
    batch = SecureRandom.hex

    PaymentCommitment.transaction do
      years_to_add.each do |year|
        period_discount = year == 0 ? discounts[0] : discounts[year - 1]
        for_year = start_year + year - aux
        payment_config = PaymentConfiguration.find(config_id)

        # TODO: calculate consortium discount based on  CONSORTIUM_DISCOUNT
        consortium_discount = 10
        attrs = {
          payment_configuration_id: config_id,
          commitment_years: commitment_years,
          note: "Create year #{year} - #{for_year} of #{commitment_years} years commitment",
          year_index: year,
          start_date: start_date,
          year: for_year,
          payment_plan: payment_config.payment_plan,
          asf: asf,
          period_discount: period_discount,
          consortium_discount: consortium_discount,
          dpc_commitment: dpc,
          dpc_carryover: 0,
          ldf_commitment: ldf,
          ldf_carryover: 0,
          asf_prepaid: asf_prepaid,
          batch: batch,
          asf_due: calculate_asf_due(asf, period_discount, consortium_discount)
        }
        record = PaymentCommitment.create(attrs)
        return record.errors.full_messages.join(', ') if record.errors.any?
      end
    end
    true
  end

  def self.calculate_asf_due(asf, period_discount, consortium_discount)
    asf_due = asf
    asf_due = asf_due * (100 - period_discount) / 100.0 if period_discount
    asf_due = asf_due * (100 - consortium_discount) / 100.0 if consortium_discount

    asf_due
  end

  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
end
