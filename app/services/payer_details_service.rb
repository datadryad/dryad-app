class PayerDetailsService
  attr_reader :payer

  def initialize(payer)
    @payer = payer
  end

  def details
    info = {
      id: payer.id,
      type: payer.class.name
    }.merge(adapter.mappings)

    OpenStruct.new(info)
  end

  private

  def adapter
    @adapter ||= "Payers::#{type}Adapter".constantize.new(payer)
  end

  def type
    type_mappings = {
      'StashEngine::Tenant' => 'Tenant',
      'StashEngine::Journal' => 'Journal',
      'StashEngine::JournalOrganization' => 'JournalOrganization',
      'StashEngine::Funder' => 'Funder'
    }

    @type ||= type_mappings[payer.class.name]
  end
end
