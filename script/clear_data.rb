module ClearData

  def self.clear_datasets
    StashEngine::Identifier.all.each do |iden|
      puts "Destroying #{iden.identifier}"
      iden.destroy
    end
    clear_solr
  end

  def self.clear_solr
    clear_solr_url = "#{Blacklight.connection_config[:url]}/update?stream.body" +
        '=<delete><query>*:*</query></delete>&commit=true'

    puts "Clearing solr with #{clear_solr_url}"

    # the following, commented out, is a query test to see if SOLR blacklight is accessible
    #response = HTTParty.get("#{Blacklight.connection_config[:url]}/select?q=*%3A*&wt=json&indent=true")
    #puts response

    # this one will actually clear things out
    response = HTTParty.get(clear_solr_url)
  end

end