class PaymentCommitmentService
  attr_reader :sponsor, :error

  # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
  def initialize(sponsor)
    @sponsor = sponsor
    @error = nil
  end

  def generate(
    commitment_years,
    asf:, dpc_tier:, covers_ldf:, ldf:, asf_prepaid: 0, start_date: Time.current,
    consortium_discount: 0,
    ldf_size_limit: 0,
    include_year_0: false
  )
    return 'Invalid commitment years, must be 1 or 3' unless commitment_years.to_i.in?([1, 3])
    return 'Start date must be a valid date' unless start_date.is_a?(Date)
    return 'ASF must be a valid number' if asf.blank?
    return 'Data Publishing Charge tier is invalid' unless valid_dpc_tier?(dpc_tier)
    return 'Large Data Fee size limit is incorrect' unless ldf_size_limit.present?

    # make dpc and dpc carryover as number of datasets based on tier input
    start_year = start_date.year
    discounts = COMMITMENT_DISCOUNTS[commitment_years.to_s]
    years_to_add, aux = if include_year_0
                          [0..commitment_years.to_i, 0]
                        else
                          [1..commitment_years.to_i, 1]
                        end
    batch = SecureRandom.hex

    PaymentCommitment.transaction do
      years_to_add.each do |year|
        period_discount = year == 0 ? discounts[0] : discounts[year - 1]
        for_year = start_year + year - aux
        payment_config = sponsor.payment_configuration
        tier = dpc_tier_info(dpc_tier)

        attrs = {
          sponsor: sponsor,
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
          covers_ldf: covers_ldf,
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
  rescue StandardError => e
    e.message
  end

  def update(payment_commitment, attrs)
    payment_commitment.assign_attributes(attrs)
    tier = dpc_tier_info(attrs[:dpc_tier])
    payment_commitment.dpc_commitment_price = tier&.[](:price)
    payment_commitment.dpc_commitment = tier&.dig(:range)&.max
    if payment_commitment.valid?
      asf_due = calculate_asf_due(attrs[:asf].to_f, attrs[:period_discount].to_f, attrs[:consortium_discount].to_f)
      payment_commitment.asf_due = asf_due
      payment_commitment.save
    end
    payment_commitment
  end

  private

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

  def valid_dpc_tier?(dpc_tier)
    dpc_tier_info(dpc_tier).present?
  end

  # rubocop:enable Metrics/MethodLength, Metrics/ParameterLists
end
