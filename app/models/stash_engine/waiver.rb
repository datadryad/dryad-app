module StashEngine
  class Waiver < ApplicationRecord
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id
    has_many :payment_records, class_name: 'PaymentRecord', as: :payment

    def self.basis_ids
      %w[
        country_not_detected
        unaware_of_dpc
        no_funds
        sponsoring_entity_updated
        political_economic_situation
        fee_increase
        temporary
        other
      ]
    end

    def self.readable(basis)
      case basis
      when 'country_not_detected'
        'Waiver country, but not detected automatically'
      when 'unaware_of_dpc'
        'Author unaware of DPC'
      when 'no_funds'
        'Author/Institution no funds'
      when 'political_economic_situation'
        'Political/Economic situation'
      when 'temporary'
        'Temporary waiver (to be replaced)'
      else
        basis.humanize
      end
    end

  end
end
