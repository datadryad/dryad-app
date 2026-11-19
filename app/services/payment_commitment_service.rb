class PaymentCommitmentService

  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists

  def generate(
    sponsor,
    commitment_years,
    asf:, dpc_tier:, ldf:, asf_prepaid:, start_date: Time.current,
    consortium_discount: 0,
    ldf_size_limit: 0,
    include_year_0: nil
  )
    # make dpc and dpc carriover as number of datasets based on tier input
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
        payment_config = sponsor.payment_configuration
        tier = dpc_tier_info(dpc_tier)

        attrs = {
          payment_configuration_id: payment_config.id,
          commitment_years: commitment_years,
          note: "Create year #{year} - #{for_year} of #{commitment_years} years commitment",
          year_index: year,
          start_date: start_date,
          year: for_year,
          payment_plan: payment_config.payment_plan,
          asf: asf,
          period_discount: period_discount,
          consortium_discount: consortium_discount,
          dpc_commitment_price: tier[:price],
          dpc_commitment: tier[:range].max,
          dpc_carryover: 0,
          ldf_commitment: ldf,
          ldf_carryover: 0,
          ldf_size_limit: ldf_size_limit,
          asf_prepaid: prepaid_asf(asf_prepaid, year, include_year_0),
          batch: batch,
          asf_due: calculate_asf_due(asf, period_discount, consortium_discount)
        }
        record = PaymentCommitment.create(attrs)
        return record.errors.full_messages.join(', ') if record.errors.any?
      end
    end
    true
  end

  def prepaid_asf(asf_prepaid, year, include_year_0)
    return asf_prepaid if year == 0 || (year == 1 && !include_year_0)

    0
  end

  def calculate_asf_due(asf, period_discount, consortium_discount)
    asf_due = asf
    asf_due = asf_due * (100 - period_discount) / 100.0 if period_discount
    asf_due = asf_due * (100 - consortium_discount) / 100.0 if consortium_discount

    asf_due
  end

  def dpc_tier_info(tier)
    ESTIMATED_DATASETS.find { |t| t[:tier] == tier.to_i }
  end

  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
end
