
Reporting
==============


Shopping Cart Report
-----------------------

The "Shopping Cart Report" is a report of how/when we collected
payment for individual datasets. It is primarily used for internal
tracking of payments.

Run it with a command like:
```
RAILS_ENV=production bundle exec rails identifiers:shopping_cart_report YEAR_MONTH=2020-01
```

Fields in the shopping cart report
- DOI
- Created Date
- Submitted Date
- Size
- Payment Type
- Payment ID
- Institution Name
- Journal Name
- Sponsor Name

To run the report and retrieve the files:
```
# On dryad-prd-a
cd apps/ui/current
RAILS_ENV=production bundle exec rake identifiers:shopping_cart_report YEAR_MONTH=2019-11

# On a stage server, copy the files:
cd shopping_cart_reports
scp dryad-prd-a:apps/ui/current/shop* .

# On your local machine, copy the files:
scp dryad-stg-a:shopping_cart_reports/shop* .
```

Dataset Info Report
---------------------

The "Dataset Info Report" is a summary report of the most important
information for individual datasets. It is primarily used to provide a
list of Dryad's contents to external users.

Run it with a command like:
```
RAILS_ENV=production bundle exec rails identifiers:dataset_info_report
```

Fields in the dataset info report
- Dataset DOI
- Article DOI
- Approval Date
- Title
- Size
- Institution Name
- Journal Name


Make Data Count / Counter Report
---------------------------------

The "Make Data Count" report runs automatically from the production
server. It uses a mix of python scripts and rake tasks to gather usage
statistics, send them to DataCite, and record copies in our database.

The main control script is `cron/counter.sh`

See the counter_stats.md for more further notes.


Administrative screen report
-----------------------------

In the Dryad user interface, administrators may export lists of
datasets from the Admin screen. These reports respect the query
selection that is active on the Admin screen, but they include more
fields than are shown in the user interface.

Fields in the admin screen CSV report
- title
- curation status
- author
- DOI
- last modified date
- last modified by
- size
- publication date
- journal name
- views
- downloads
- citations

Authors at an Institution Report (from SQL)
-------------------------------------------

This SQL may be more complicated than it needs to be, but it seems to work.  It gives information about
published and embargoed items with authors at an institution based on the ROR ids you put into the query
(look and replace in two separate places).
It can then be exported from SQL as TSV/CSV or whatever.  There are duplicate rows per dataset if more
than one author is from the institution that contributed to the same dataset.  The views and downloads may
be off if we go to a model where we retrieve them in real-time from DataCite because they come from
multiple sources (like us and Zenodo) and we don't pre-populate them all the time.

It includes published and embargoed (shows the landing page but no downloads) which is why some
publication dates are in the future.

Sorry, IDK why the markdown seems to do it's own thing when indenting, even if I do it preformatted.

<pre>
SELECT se_id3.identifier, se_res3.title, se_auth3.author_first_name, se_auth3.author_last_name, dcs_affil3.long_name, se_res3.publication_date,
(stash_engine_counter_stats.unique_investigation_count - stash_engine_counter_stats.unique_request_count) as unique_views, stash_engine_counter_stats.unique_request_count as unique_downloads
FROM
  /* get only the earliest published/embagoed one */
  (SELECT unique_ids.identifier_id, min(res2.id) first_pub_resource FROM
    /* only get distinct identifiers from all the ror_ids working back through zillions of joined tables */
    (SELECT DISTINCT se_id.id as identifier_id
	    FROM dcs_affiliations affil
	    JOIN dcs_affiliations_authors affil_auth
	    ON affil.id = affil_auth.`affiliation_id`
	    JOIN stash_engine_authors auth
	    ON affil_auth.`author_id` = auth.`id`
	    JOIN stash_engine_resources res
	    ON auth.`resource_id` = res.id
	    JOIN stash_engine_identifiers se_id
	    ON se_id.id = res.identifier_id
	    WHERE affil.ror_id IN ('https://ror.org/02y3ad647', 'https://ror.org/0419bgt07', 'https://ror.org/04tk2gy88')
	    AND se_id.pub_state IN ('published', 'embargoed')) as unique_ids
  JOIN stash_engine_resources res2
  ON unique_ids.identifier_id = res2.identifier_id
  WHERE res2.publication_date IS NOT NULL
  GROUP BY unique_ids.identifier_id) as ident_and_res	
JOIN stash_engine_identifiers se_id3
ON se_id3.id = ident_and_res.identifier_id
JOIN stash_engine_resources se_res3
ON se_res3.id = ident_and_res.first_pub_resource
JOIN stash_engine_authors se_auth3
ON se_res3.id = se_auth3.`resource_id`
JOIN dcs_affiliations_authors dcs_affils_authors3
ON se_auth3.`id` = dcs_affils_authors3.`author_id`
JOIN dcs_affiliations dcs_affil3
ON dcs_affils_authors3.`affiliation_id` = dcs_affil3.`id`
LEFT JOIN stash_engine_counter_stats
ON se_id3.id = stash_engine_counter_stats.`identifier_id`
WHERE dcs_affil3.ror_id IN ('https://ror.org/02y3ad647', 'https://ror.org/0419bgt07', 'https://ror.org/04tk2gy88')
ORDER BY se_res3.publication_date, se_id3.identifier, se_res3.title;
</pre>
