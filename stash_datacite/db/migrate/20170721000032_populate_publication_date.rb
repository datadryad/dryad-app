class PopulatePublicationDate < ActiveRecord::Migration
  # Sets the publication date for each submitted resource (i.e., each resource
  # for which we have an identifier), as:
  #
  # 1. the embargo end date, if any
  # 2. the DataCite 'date available', if any
  # 3. the date the identifier was minted (which should correspond closely
  #    to the submission time
  #
  # Note that the identifier mint date is not strictly accurate for data migrated
  # from Dash 1 (it's based on the timestamp of the identifier record in the database),
  # but those records should all have DataCite dates.
  def change
    pub_dates = {}
    [embargo_end_dates, dcs_dates_available, id_mint_dates].each do |result|
      result.each do |row|
        resource_id = row['resource_id']
        pub_date = row['publication_date']
        pub_dates[resource_id] ||= pub_date
      end
    end

    values = pub_dates.values.map { |date| { publication_date: date } }
    StashEngine::Resource.update(pub_dates.keys, values)
  end

  # Finds all embargo end dates for resources with identifiers
  # @return [ActiveRecord::Result] each resource ID and embargo end date, as:
  #   * :resource_id [Integer] the resource ID
  #   * :publication_date [Datetime] the embargo end date
  def embargo_end_dates
    ActiveRecord::Base.connection.exec_query <<-SQL
        SELECT r.id AS resource_id,
               e.end_date AS publication_date
          FROM stash_engine_resources r,
               stash_engine_embargoes e
         WHERE r.id = e.resource_id
           AND r.identifier_id IS NOT NULL
      ORDER BY resource_id
    SQL
  end

  # Finds all DataCite 'available' dates for resources with identifiers
  # @return [ActiveRecord::Result] each resource ID and DataCite 'available' date, as:
  #   * :resource_id [Integer] the resource ID
  #   * :publication_date [Datetime] the DataCite 'available' date
  def dcs_dates_available
    ActiveRecord::Base.connection.exec_query <<-SQL
        SELECT r.id AS resource_id,
               CAST(d.date AS DATETIME) AS publication_date
          FROM stash_engine_resources r,
               dcs_dates d
         WHERE r.id = d.resource_id
           AND d.date_type = 'available'
           AND r.identifier_id IS NOT NULL
      ORDER BY resource_id
    SQL
  end

  # Finds all identifier minting dates for resources with identifiers
  #
  # Note that the identifier mint date is not strictly accurate for data migrated
  # from Dash 1 (it's based on the timestamp of the identifier record in the database),
  # but those records should all have DataCite dates.
  # @return [ActiveRecord::Result] each resource ID and identifier minting date, as:
  #   * :resource_id [Integer] the resource ID
  #   * :publication_date [Datetime] the identifier minting date
  def id_mint_dates
    ActiveRecord::Base.connection.exec_query <<-SQL
        SELECT r.id AS resource_id,
               i.created_at AS publication_date
          FROM stash_engine_resources r,
               stash_engine_identifiers i
         WHERE r.identifier_id = i.id
      ORDER BY resource_id
    SQL
  end

end
