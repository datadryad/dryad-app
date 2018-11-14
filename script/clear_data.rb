module ClearData

  def self.clear
    to_truncate = %w(bookmarks dcs_affiliations_contributors
      dcs_alternate_identifiers dcs_contributors dcs_dates dcs_descriptions
      dcs_formats dcs_geo_location_boxes dcs_geo_location_places dcs_geo_location_points dcs_geo_locations
      dcs_languages dcs_name_identifiers dcs_publication_years dcs_publishers dcs_related_identifiers
      dcs_resource_types dcs_rights dcs_sizes dcs_subjects_stash_engine_resources
      dcs_versions searches stash_engine_authors stash_engine_embargoes stash_engine_file_uploads stash_engine_identifiers
      stash_engine_resource_states stash_engine_resource_usages stash_engine_resources stash_engine_submission_logs
      stash_engine_versions users)

    to_truncate.each do |t|
      query = "TRUNCATE TABLE #{t}"
      result = ActiveRecord::Base.connection.execute(query)
      puts "Truncating table #{t}"
    end

    query = "DELETE FROM dcs_affiliations WHERE abbreviation IS NULL AND short_name IS NULL"
    result = ActiveRecord::Base.connection.execute(query)
    puts "Removing extra records from affiliations"

    clear_solr
  end

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