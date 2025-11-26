# :nocov:
require 'rsolr'
module ClearData

  def self.clear_data
    clear_datasets
    clear_solr
  end

  def self.clear_datasets
    StashEngine::Identifier.all.each do |iden|
      puts "Destroying #{iden.identifier}"
      iden.destroy
    end
  end

  # this now gives "stream Body id disabled"
  def self.clear_solr
    puts "Clearing solr data"

    solr = RSolr.connect url: APP_CONFIG.solr_url
    solr.delete_by_query("*:*")
    solr.commit
  end

end
# :nocov:
