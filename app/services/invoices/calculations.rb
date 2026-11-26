require 'csv'

module Invoices
  class Calculations
    include ActionView::Helpers::NumberHelper

    attr_reader :commitment, :sponsor, :year, :result

    def initialize(payment_commitment, sponsor, year)
      @commitment = payment_commitment
      @sponsor = sponsor
      @year = year
      @result = []
      @dpc_overage_charges = 0
      @covers_dpc = sponsor.payment_configuration&.covers_dpc?
      @covers_ldf = sponsor.payment_configuration&.covers_ldf?
    end

    def generate
      raise 'Invalid sponsor' unless sponsor.present?
      raise 'Sponsor contract is not configured' unless commitment.present?

      add_contract_details
      add_separator
      add_separator
      add_invoice_summary
      add_separator
      if @covers_dpc
        add_dpc_year_usage
        add_separator
      end
      if @covers_ldf
        add_ldf_year_usage
        add_separator
      end
      prepayment_balance
      add_separator
      next_year_summary
      add_separator
      invoice_totals
      add_separator

      [result, @total_current_invoice]
    end

    private

    # rubocop:disable Metrics/AbcSize
    def add_contract_details
      result << ([''] + commitment_records.map { |item| "Year #{item.year_index}" })
      result << (['Year'] + commitment_records.map(&:year))
      result << (['Annual Service Fee'] + commitment_records.map(&:asf).map { |a| formatted_amount(a) })
      result << (["Discount - #{commitment.commitment_years} year"] + commitment_records.map(&:period_discount).map { |a| percent(a) })
      if commitment.consortium_discount.present?
        result << (['Discount - Consortium'] + commitment_records.map(&:consortium_discount).map do |a|
          percent(a)
        end)
      end
      result << (['Annual Service Fee Bue'] + commitment_records.map(&:asf_due).map { |a| formatted_amount(a) })
      add_separator
      result << (['Prepaid (Flexible)'] + commitment_records.map(&:asf_prepaid).map { |a| formatted_amount(a) })
    end

    def add_invoice_summary
      asf_subtotal = current_commitment.asf * (100 - current_commitment.period_discount) / 100
      asf_paid = current_commitment.asf_due
      raise('Annual service fee Paid do not match') if asf_paid != asf_subtotal * (100 - current_commitment.consortium_discount) / 100

      result << ["#{year} Invoice Summary:", '']
      result << ['Annual Service Fee', formatted_amount(current_commitment.asf)]
      result << ["Discount (Year #{current_commitment.year_index})",
                 formatted_amount(-1 * current_commitment.asf * current_commitment.period_discount / 100)]
      result << ['Annual Service Fee Subtotal', formatted_amount(asf_subtotal)]
      result << ['Discount (Consortium)', formatted_amount(-1 * asf_subtotal * current_commitment.consortium_discount / 100)]
      result << ['Annual Service Fee Paid', formatted_amount(asf_paid)]
      result << ['Data Publishing Charge Paid', formatted_amount(current_commitment.dpc_commitment_price)] if @covers_dpc
      result << ['Large Data Paid', formatted_amount(current_commitment.ldf_commitment)] if @covers_ldf
      result << ['Additional Prepayment', formatted_amount(current_commitment.asf_prepaid)]

      # all paid payment amounts, including prepayment
      @total_current_invoice = asf_paid + current_commitment.dpc_commitment_price + current_commitment.ldf_commitment
      @total_next_invoice = @total_current_invoice
      @asf_prepaid_for_next_year = current_commitment.asf_prepaid - @total_current_invoice
      @asf_prepaid_for_next_year = 0 if @asf_prepaid_for_next_year < 0
      # result << ['Total Paid', formatted_amount(current_commitment.asf_prepaid - @total_current_invoice)]
      result << ['Total Paid', formatted_amount(@total_current_invoice)]
    end

    def add_dpc_year_usage
      total = current_commitment.dpc_commitment + current_commitment.dpc_carryover
      @dpc_for_next_year = total - consumed_dpc
      @dpc_overage_charges = 0

      if @dpc_for_next_year < 0
        @dpc_overage_charges = @dpc_for_next_year.abs * 125
        @dpc_for_next_year = 0
      end

      @total_next_invoice += @dpc_overage_charges
      result << ["#{year} Usage Summary:", '']
      result << ["Total DPC Available to use in #{year}", total]
      result << ["DPC Commitment Paid in #{year}", current_commitment.dpc_commitment]
      result << ['DPC Carryover from Previous Year', current_commitment.dpc_carryover]
      result << ["Total DPC Consumed in #{year}", consumed_dpc]
      result << ["Total DPC Remaining for Carryover to #{year + 1}", @dpc_for_next_year]
      result << ['DPC Charge (only applies for overage)', formatted_amount(@dpc_overage_charges)]
    end

    def add_ldf_year_usage
      total = @commitment.ldf_commitment + @commitment.ldf_carryover.to_f
      @ldf_for_next_year = total - consumed_ldf

      result << ["Large Data Available to use in #{year}", formatted_amount(total)]
      result << ["Large Data Commitment in #{year}", formatted_amount(@commitment.ldf_commitment)]
      result << ['Large Data Carryover from Previous Year', formatted_amount(@commitment.ldf_carryover.to_f)]
      result << ['Total Large Data Consumed', formatted_amount(consumed_ldf)]
      result << ["Total Large Data Remaining for Carryover to #{year + 1}", formatted_amount(@ldf_for_next_year)]
    end

    def prepayment_balance
      result << ['Starting Prepayment Balance', formatted_amount(@commitment.asf_prepaid)]
      result << ["#{year} Additional Charges for Usage above Commitment", formatted_amount(@dpc_overage_charges.abs)]
      result << ['Prepayment Used to Cover Additional Charges', formatted_amount(-@dpc_overage_charges.abs)]
      result << ['Additional Amount Due on Invoice', formatted_amount(@total_current_invoice)]
      result << ['Prepayment Balance Available for Future Use', formatted_amount(@asf_prepaid_for_next_year)]
    end

    def next_year_summary
      return unless next_commitment

      asf_subtotal = next_commitment.asf * (100 - next_commitment.period_discount) / 100
      asf_paid = next_commitment.asf_due
      raise('Annual service fee Paid do not match') if asf_paid != asf_subtotal * (100 - current_commitment.consortium_discount) / 100

      result << ["#{next_commitment.year} Invoice Summary:", '']
      result << ['Annual Service Fee', formatted_amount(next_commitment.asf)]
      result << ["Discount (Year #{next_commitment.year_index})", formatted_amount(-1 * next_commitment.asf * next_commitment.period_discount / 100)]
      result << ['Annual Service Fee Subtotal', formatted_amount(asf_subtotal)]
      result << ['Discount (Consortium)', formatted_amount(-1 * asf_subtotal * next_commitment.consortium_discount / 100)]
      result << ['Annual Service Fee Due', formatted_amount(next_commitment.asf_due)]
      add_separator
      @total_next_invoice = next_commitment.asf_due + next_commitment.dpc_commitment_price + next_commitment.ldf_commitment

      if @covers_dpc
        result << ['Data Publishing Charge (# of datasets)', next_commitment.dpc_commitment]
        result << ['Data Publishing Charge Carryover Credit (Due)', @dpc_for_next_year]
        result << ['Data Publishing Charge - Amount due', formatted_amount(next_commitment.dpc_commitment_price)]
        add_separator
      end
      return unless @covers_ldf

      result << ['Large Data Fee - Based on Previous Year Usage', formatted_amount(next_commitment.ldf_commitment)]
      result << ['Large Data Fee - Carryover Credit (Due)', formatted_amount(@ldf_for_next_year)]
      result << ['Large Data Fee - Amount Due', formatted_amount(next_commitment.ldf_commitment + @ldf_for_next_year)]
    end

    def invoice_totals
      result << ['Total Amount Due', formatted_amount(@total_next_invoice)]
      result << ['Prepayment Credit Applied', formatted_amount(@asf_prepaid_for_next_year)]
      result << ['Total Amount Due net of Prepayments', formatted_amount(@total_next_invoice - @asf_prepaid_for_next_year)]
    end

    # rubocop:enable Metrics/AbcSize
    def add_separator
      result << ['']
    end

    def tier_by_price(tier_definition, price)
      sorted = tier_definition.sort_by { |dataset| -dataset[:price] }
      sorted.find { |dataset| dataset[:price] <= price }
    end

    def consumed_dpc
      Payments::Sponsor.new(sponsor, year: year).invoice_identifiers.count
    end

    def consumed_ldf
      @consumed_ldf ||= Payments::Sponsor.new(sponsor, year: year).spent_ldf
    end

    def formatted_amount(amount)
      precision = amount == amount.to_i ? 0 : 2
      number_to_currency amount, precision: precision
    end

    def percent(amount)
      "#{amount}%"
    end

    def commitment_records
      @commitment_records ||= PaymentCommitment.where(batch: commitment.batch).order(year_index: :asc)
    end

    def current_commitment
      @current_commitment ||= commitment_records.find { |item| item.year.to_i == year.to_i }
    end

    def next_commitment
      @next_commitment ||= PaymentCommitment.where(year: year + 1, sponsor: sponsor).first
    end
  end
end
