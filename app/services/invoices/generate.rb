# frozen_string_literal: true

require 'csv'

module Invoices
  class Generate
    include ActionView::Helpers::NumberHelper

    attr_reader :commitment, :year, :csv

    def initialize(payment_commitment, year)
      @commitment = payment_commitment
      @year = year
      @csv = []
    end

    def call
      add_contract_details
      add_separator
      add_separator
      add_separator
      add_invoice_details
      add_separator
      add_year_usage
      add_separator

      finalize_csv
    end

    private

    # rubocop:disable Metrics/AbcSize
    def add_contract_details
      csv << ([''] + commitment_records.map { |item| "Year #{item.year_index}" })
      csv << (['Year'] + commitment_records.map(&:year))
      csv << (['Annual Service Fee'] + commitment_records.map(&:asf).map { |a| af(a) })
      csv << (["Discount - #{commitment.commitment_years} year"] + commitment_records.map(&:period_discount).map { |a| af(a) })
      csv << (['Discount - Consortium'] + commitment_records.map(&:consortium_discount).map { |a| af(a) }) if commitment.consortium_discount.present?
      csv << (['Annual Service Fee Bue'] + commitment_records.map(&:asf_due).map { |a| af(a) })
      add_separator
      csv << (['Prepaid ASF'] + commitment_records.map(&:asf_due).map { |a| af(a) })
      csv << (['Prepaid DPC'] + commitment_records.map(&:dpc_commitment).map { |a| af(a) })
      csv << (['Prepaid Large Data'] + commitment_records.map(&:ldf_commitment).map { |a| af(a) })
      csv << (['Prepaid (Flexible)'] + commitment_records.map(&:asf_prepaid).map { |a| af(a) })
    end

    def add_invoice_details
      asf_subtotal = current_commitment.asf * (100 - current_commitment.period_discount) / 100
      asf_paid = current_commitment.asf_due
      raise('Annual service fee Paid do not match') if asf_paid != asf_subtotal * (100 - current_commitment.consortium_discount) / 100

      csv << ["#{year} Invoice Summary:"]
      csv << ['Annual Service Fee', af(current_commitment.asf)]
      csv << ["Discount (Year #{current_commitment.year_index})", af(-1 * current_commitment.asf * current_commitment.period_discount / 100)]
      csv << ['Annual Service Subtotal', af(asf_subtotal)]
      csv << ['Discount (Consortium)', af(-1 * asf_subtotal * current_commitment.consortium_discount / 100)]
      csv << ['Annual Service Fee Paid', af(asf_subtotal * (100 - current_commitment.consortium_discount) / 100)]
      csv << ['Data Publishing Charge Paid', af(current_commitment.dpc_commitment)]
      csv << ['Large Data Paid', af(current_commitment.ldf_commitment)]
      csv << ['Additional Prepayment', af(current_commitment.asf_prepaid)]

      total = asf_paid + current_commitment.dpc_commitment + current_commitment.ldf_commitment + current_commitment.asf_prepaid
      csv << ['Total Paid', af(total)]
    end

    def add_year_usage
      tier = tier_by_price(ESTIMATED_DATASETS, current_commitment.dpc_commitment)
      tier_dpc = tier ? tier[:range].max : 0
      carryover_tier = tier_by_price(ESTIMATED_DATASETS, current_commitment.dpc_carryover)
      carryover_dpc = carryover_tier ? carryover_tier[:range].max : 0

      csv << ["#{year} Usage Summary:"]
      csv << ["Total DPC Available to use in #{year}", tier_dpc + carryover_dpc]
      csv << ["DPC Commitment Paid in #{year}", tier_dpc]
      csv << ['DPC Carryover from Previous Year', carryover_dpc]
      csv << ["Total DPC Consumed in #{year}", consumed_dpc]
      csv << ['DPC Charge (only applies for overage)']
      add_separator
      csv << ["Large Data Available to use in #{year}"]
      csv << ["Large Data Commitment in #{year}"]
      csv << ['Large Data Carryover from Previous Year']
      csv << ['Total Large Data Consumed']
      csv << ["Total Large Data Remaining for Carryover to #{year + 1}"]
      csv << ['Large Data Charge (only applies for overage)']
      csv << [tier_by_price(ESTIMATED_DATASETS, current_commitment.dpc_commitment)]
    end

    # rubocop:enable Metrics/AbcSize
    def add_separator
      csv << ['']
    end

    def finalize_csv
      CSV.open(File.join(REPORTS_DIR, 'invoice.csv'), 'w') do |csv_instance|
        csv.each do |row|
          csv_instance << row
        end
      end
    end

    def tier_by_price(tier_definition, price)
      sorted = tier_definition.sort_by { |dataset| -dataset[:price] }
      sorted.find { |dataset| dataset[:price] < price }
    end

    def sponsor
      # return StashEngine::Tenant.find('mit')
      @sponsor ||= current_commitment.payment_configuration.partner
    end

    def consumed_dpc
      Payments::Sponsor.new(sponsor).identifiers.count
    end

    def af(amount)
      number_to_currency amount
    end

    def commitment_records
      @commitment_records ||= PaymentCommitment.where(batch: commitment.batch).order(year_index: :asc)
    end

    def current_commitment
      @current_commitment ||= commitment_records.find { |item| item.year.to_i == year.to_i }
    end
  end
end
