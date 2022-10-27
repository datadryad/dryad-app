module StashEngine
  class AdminFundersController
    class Report

      # this base query is complicated but gets all the stuff we need for filtering and sorting into one query
      # (see the SELECT list) so that it can do all the good stuff.  Then in order to SORT, add conditions (WHERE),
      # or LIMIT we have to build up additional parts and add to the query and be sure to always be sure SQL injection
      # from user input is not possible
      #
      # I looked into trying to reuse an activerecord model or using Arel instead, but both seemed more difficult

      BASE_QUERY = <<~SQL.freeze
        SELECT ids.id, last_res.title, ids.identifier, contrib.contributor_name, contrib.name_identifier_id,
               contrib.award_number, ids.pub_state, init_sub_date, last_viewable.max_resource_id as last_viewable_resource_id,
               viewable_resource.publication_date,
               (SELECT GROUP_CONCAT(author_last_name ORDER BY author_last_name SEPARATOR '; ')
               FROM stash_engine_authors WHERE resource_id = last_res.id) as authors
        FROM stash_engine_identifiers ids
          JOIN stash_engine_resources last_res
            ON ids.latest_resource_id = last_res.id
          JOIN dcs_contributors contrib
            ON ids.latest_resource_id = contrib.resource_id
          LEFT JOIN (SELECT identifier_id, MIN(stash_engine_resource_states.updated_at) init_sub_date
                      FROM stash_engine_resources
                      JOIN stash_engine_resource_states
                      ON stash_engine_resources.id = stash_engine_resource_states.resource_id
                      WHERE resource_state = 'submitted' GROUP BY identifier_id) as init_sub
            ON ids.id = init_sub.identifier_id
          LEFT JOIN ( SELECT identifier_id, max(id) max_resource_id
                      FROM stash_engine_resources
                      WHERE meta_view = 1
                      GROUP BY identifier_id) last_viewable
            ON ids.id = last_viewable.identifier_id
          LEFT JOIN stash_engine_resources viewable_resource
            ON last_viewable.max_resource_id = viewable_resource.id
        WHERE contrib.contributor_type = 'funder'
      SQL

      def initialize
        @where_conditions = ''
        @where_params = []
        @limit = ''
        @order_by = ''
      end

      # this takes a typical Rails-style conditional array with first condition the SQL w/ question marks and the
      # rest of the arguments are the arguments that get escaped
      def add_where(arr:)
        @where_conditions << " AND (#{arr.first}) " # put in parenthesis for good measure
        @where_params << arr[1..-1]
        @where_params.flatten!
      end

      def add_limit(offset:, rows:)
        @limit = " LIMIT #{offset.to_i}, #{rows.to_i}" # this should only have ints, but may be 0 for non-int strings
      end

      # eliminate all SQL injection before passing this string in with helper
      def order(order_str:)
        @order_by = "ORDER BY #{order_str}"
      end

      # returns a hash like this:
      # {"id"=>2997,                                                        -- The identifier_id
      #  "title"=>"Big Amazing S3 upload test",                             -- Title
      #  "identifier"=>"10.7959/dryad.jsxksn32",                            -- Bare doi
      #  "contributor_name"=>"Raymond F. Baker Center for Plant Breeding",  -- contributor (funder) name
      #  "name_identifier_id"=>"http://dx.doi.org/10.13039/100015830",      -- crossref funder ID
      #  "award_number"=>"plant387",                                        -- The award number user put in for funder
      #  "pub_state"=>"unpublished",                                        -- identifier.pub_state (unpublished, withdrawn, published, embargoed)
      #  "init_sub_date"=>2022-02-02 02:29:12 UTC,                          -- Earliest submitted state from stash_engine_resource_states
      #  "last_viewable_resource_id"=>2997,                                 -- last resource with view flag set (embargoed or published)
      #  "publication_date"=>2020-08-10 00:00:00 UTC,                       -- pub date for last view resource, may be embargoed (future) or published (past)
      #  "authors"=>"Account"}                                              -- author last names
      def do_query
        # this needs to be expanded
        query = "#{BASE_QUERY} #{@where_conditions} #{@order_by} #{@limit}"
        # ActiveRecord::Base.connection.select_all([query, @where_params].flatten)
        StashEngine::Identifier.find_by_sql([query, @where_params].flatten)
      end
    end
  end
end
