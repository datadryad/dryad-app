Dryad's reports contain a number of dates. For details on the meaning of the
dates, see the [dates technical note](technical_notes/dates.md).

"Shopping cart" reporting
=======================

Long ago, Dryad users put their data files into an electronic "shopping cart",
and at the end of the uploading process, they would "check out" their cart. The
monthly reports of data publications became known as reports of the shopping
cart system, and we still use that terminology.

Shopping cart report
-----------------------

The "Shopping Cart Report" is a report of how/when we collected
payment for individual datasets. It is primarily used for internal
tracking of payments.

Run it with a command like:
```
RAILS_ENV=production bundle exec rake identifiers:shopping_cart_report -- --year_month 2024-01
```

Fields in the shopping cart report
- DOI
- Created Date
- Curation Start Date
- Size
- Payment Type
- Payment ID
- Waiver Basis
- Institution Name
- Journal Name
- Sponsor Name

To run the report and retrieve the files:
```
# on v3-prod server
cd ~/deploy/current
RAILS_ENV=production bundle exec rake identifiers:shopping_cart_report -- --year_month 2024-01
cp ~/deploy/current/shopping* ~/journal-payments/shoppingcart/
cd ~/journal-payments/shoppingcart
git pull
git add <new-file>
git commit -a -m "add reports for 2024-01"
git push origin main
```

End-of-quarter reporting
------------------------

At the end of a quarter, combine the three monthly files into a single quarterly
file so it can be used for the quarterly reports below. If there is more than
one quarterly file for the year, combine them into a yearly file, so it can be
used to calculate "base rates".

### Deferred payment reports

For journals that have a deferred payment plan, a secondary task generates
PDF reports that can be be sent to the journal sponsors. The secondary task
takes as input a shopping_cart_report. This report may be one of the individual
reports generated above, or it may be a report for a longer timespan (quarter,
year) generated by combining multiple shopping_cart_reports.

Run the deferred payment reports with a command like:
```
cp ~/journal-payments/shoppingcart/2024/* /tmp
# This command must be run on the v3-prod server, to access the production database
RAILS_ENV=production bundle exec rake identifiers:deferred_journal_reports -- --sc_report /tmp/shopping_cart_report_2024-Q1.csv
```

Copy the resultant files into their respective places in `~/journal-payments/`

### Tiered payment reports

For journals that have a tiered payment plan, a secondary task generates PDF
reports that can be be sent to the journal sponsors. The secondary task takes as
input a shopping_cart_report, as generated above, but it also needs a cumulative
shopping_cart_report for prior quarters, including the current quarter, to
calculate the "base rate".
file.

Run the tiered journal payment reports with a command like:
```
# This command must be run in a personal account with the journal-payments checked out
cp ~/journal-payments/shoppingcart/2024* /tmp
# This command must be run on the production server, to access the production database

RAILS_ENV=production bundle exec rake identifiers:tiered_journal_reports -- --sc_report /tmp/shopping_cart_report_2023-Q1.csv --base_report /tmp/shopping_cart_report_2023.csv
```

For tenant institutions that have a tiered payment plan, a similar secondary task
generates PDF reports that can be sent to the institution. The task takes as input
the same quarterly shopping_cart_report and "base rate" cumulative 
shopping_cart_report as above.

Run the tiered institution payment reports with a command like:
```
# This command must be run in a personal account with the journal-payments checked out
cp ~/journal-payments/shoppingcart/2024* /tmp
# This command must be run on the production server, to access the production database

RAILS_ENV=production bundle exec rake identifiers:tiered_tenant_reports -- --sc_report /tmp/shopping_cart_report_2023-Q1.csv --base_report /tmp/shopping_cart_report_2023.csv
```

Copy the resultant files into their respective places in `~/journal-payments/`

Dataset info report
===================

The "Dataset Info Report" is a summary report of the most important
information for individual datasets. It is primarily used to provide a
list of Dryad's contents to external users.

Run it with a command like:
```
RAILS_ENV=production bundle exec rake identifiers:dataset_info_report
```

Fields in the dataset info report
- Dataset DOI
- Article DOI
- Approval Date
- Title
- Size
- Institution Name
- Journal Name


Geographic authors report
=========================

The Geographic authors report lists all authors of publicly viewable Dryad datasets,
with their institutions and countries, in geographic_authors_report.csv.

Run it with a command like:
```
RAILS_ENV=production bundle exec rake identifiers:geographic_authors_report
```


Make Data Count / Counter report
================================

The "Make Data Count" report runs automatically from the production
server. It uses a mix of python scripts and rake tasks to gather usage
statistics, send them to DataCite, and record copies in our database.

The main control script is `cron/counter.sh`

See the counter_stats.md for more further notes.


Administrative screen report
============================

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


Curation stats reports
======================

Curation stats depend on the history of each dataset. Calculating them from
scratch would require touching every dataset in Dryad, so we cache the results
in a database table `stash_engine_curation_stats`, with one row for each
day. These rows can be recalculated if needed (e.g., if we add new stats).

Some of the curation stats start with the word 'new'. This indicates that they
only apply to newly-created datasets, the first time the dataset is
processed. For stats without the word 'new', the stat applies to each version of
the dataset, typically for the purpose of monitoring throughput of the curation
workflow.


Statistics for the annual report
================================

For the annual report, we rely on these high-level numbers:
- data publications: go to the search page and see how many publications we
  currently have
- authors: `select count(distinct author_first_name, author_last_name) from stash_engine_authors;`
- institutions: `select count(distinct long_name) from dcs_affiliations;`
- journals: `select distinct value from stash_engine_internal_data where data_type='publicationISSN';`


Datasets affiliated with an institution
=======================================

When talking to institutions, we may want to give them information about datasets with some
connection to their institution. This takes into account both author affiliations and funding
related to the institution. It takes a string and returns any that have that as a substring.
This also gives institutions when people didn't autocomplete their ROR correctly.

Run like:

```
RAILS_ENV=production bundle exec rake reports:from_text_institution -- --name="Planck"
```

Put the string you want to detect in the `name` variable. It shows the matches in `author_affiliations`
and `contributor_affiliations` in the tabular data output.


Authors at an institution report (from SQL)
===========================================

This SQL may be more complicated than it needs to be, but it seems to work. It gives information about
published and embargoed items with authors at an institution based on the ROR ids you put into the query
(look and replace in two separate places).
It can then be exported from SQL as TSV/CSV or whatever. There are duplicate rows per dataset if more
than one author is from the institution that contributed to the same dataset. The views and downloads may
be off if we go to a model where we retrieve them in real-time from DataCite because they come from
multiple sources (like us and Zenodo) and we don't pre-populate them all the time.

It includes published and embargoed (shows the landing page but no downloads) which is why some
publication dates are in the future.

```sql
SELECT se_id3.identifier, se_res3.title, se_auth3.author_first_name, se_auth3.author_last_name, se_auth3.author_email, dcs_affil3.long_name, se_id3.payment_type, se_id3.payment_id, se_id3.created_at, se_res3.publication_date,
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
```

# See all institutions associated with all authors for dataset (all versions, all statuses)
(replace the identifier with the one you want to see).
```sql
SELECT res.id as resource_id, res.created_at resource_created, resource_id, affil.*
  FROM stash_engine_identifiers ids
	JOIN stash_engine_resources res
      ON ids.id = res.identifier_id
    JOIN stash_engine_authors auth
      ON res.id = auth.resource_id
    JOIN dcs_affiliations_authors aff_auth
      ON auth.id = aff_auth.author_id
    JOIN dcs_affiliations affil
      ON aff_auth.affiliation_id = affil.id
  WHERE ids.identifier = '10.5061/dryad.k0p2ngfb1'
  ORDER BY res.id;
```

# See all unique DOIs associated with authors at institutions (all versions, all statuses)

Replace the list of ROR institutions and only works when people have filled in the
RORs correctly.

```sql
SELECT DISTINCT ids.identifier
  FROM stash_engine_identifiers ids
	JOIN stash_engine_resources res
      ON ids.id = res.identifier_id
    JOIN stash_engine_authors auth
      ON res.id = auth.resource_id
    JOIN dcs_affiliations_authors aff_auth
      ON auth.id = aff_auth.author_id
    JOIN dcs_affiliations affil
      ON aff_auth.affiliation_id = affil.id
  WHERE affil.ror_id IN ('https://ror.org/01q1z8k08', 'https://ror.org/008rmbt77', 'https://ror.org/05ms04m92', 'https://ror.org/0306aeb62', 'https://ror.org/02n1c7856', 'https://ror.org/057trrr89', 'https://ror.org/02rrhsz92', 'https://ror.org/00qv0tw17', 'https://ror.org/05vrs0r17', 'https://ror.org/03g1q6c06', 'https://ror.org/02r3ym141', 'https://ror.org/033zmj163', 'https://ror.org/000fxgx19', 'https://ror.org/040kfrw16', 'https://ror.org/05a4pj207', 'https://ror.org/02v9m6h26', 'https://ror.org/02d4maz67', 'https://ror.org/03j3dv688', 'https://ror.org/01597g643', 'https://ror.org/032qgrc76', 'https://ror.org/05qghxh33', 'https://ror.org/012zs8222', 'https://ror.org/01y64my43', 'https://ror.org/0041qmd21');
```

# See all DOIs submitted under a tenant
(Change tenant ids below to the ones you want to see)
```sql
SELECT DISTINCT ids.identifier
  FROM stash_engine_identifiers ids
    JOIN stash_engine_resources res
    ON ids.id = res.identifier_id
  WHERE res.tenant_id IN ('buffalo', 'buffalostate', 'stonybrook', 'suny');
```

# See all DOIs submitted by a user who is associated with a tenant (all versions, all statuses)
(Change tenant ids below to the ones you want to see)

This may not match the tenant id in the dataset since users may have their affiliation changed later
after making submissions. Users have their tenant_id association set after bringing
a new tenant on board by searching for users with emails at an institution.

```sql
SELECT DISTINCT ids.identifier
  FROM stash_engine_identifiers ids
    JOIN stash_engine_resources res
      ON ids.id = res.identifier_id
    JOIN stash_engine_users users
      ON res.user_id = users.id
  WHERE users.tenant_id IN ('buffalo', 'buffalostate', 'stonybrook', 'suny');
```

Unique authors from ROR institutions (from SQL)
===============================================

This is an example of a query getting unique author last, first and institution names. This is an example of UCs and Lawrence Berkeley Lab.

There are lots of duplicate authors who seem to be entering their names in slightly different ways or saying they're from different institutions (or spelling them differently).

In order to get a really unique count, it probably needs to be gone through by hand and eliminate seeming duplicates and it still might not be
100% accurate, but would be close.

```sql
SELECT DISTINCT auths.`author_first_name`, auths.`author_last_name`, affils.`long_name` FROM stash_engine_authors auths
JOIN dcs_affiliations_authors aa
ON auths.id = aa.`author_id`
JOIN `dcs_affiliations` affils
ON aa.`affiliation_id` = affils.`id`
WHERE affils.`ror_id` IN ('https://ror.org/01an7q238', 'https://ror.org/03djjyk45', 'https://ror.org/01ewh7m12', 'https://ror.org/03rafms67', 'https://ror.org/05kbg7k66', 'https://ror.org/02mmp8p21', 'https://ror.org/05rrcem69', 'https://ror.org/05q8kyc69', 'https://ror.org/05ehe8t08', 'https://ror.org/00fyrp007', 'https://ror.org/05t6gpm70', 'https://ror.org/04gyf1771', 'https://ror.org/03fgher32', 'https://ror.org/00cm8nm15', 'https://ror.org/03bfp2076', 'https://ror.org/046rm7j60', 'https://ror.org/05h4zj272', 'https://ror.org/04p5baq95', 'https://ror.org/03b66rp04', 'https://ror.org/04k3jt835', 'https://ror.org/01d88se56', 'https://ror.org/04vq5kb54', 'https://ror.org/00mjfew53', 'https://ror.org/00d9ah105', 'https://ror.org/00pjdza24', 'https://ror.org/03nawhv43', 'https://ror.org/02t274463', 'https://ror.org/03s65by71', 'https://ror.org/0168r3w48', 'https://ror.org/01kbfgm16', 'https://ror.org/04mg3nk07', 'https://ror.org/05ffhwq07', 'https://ror.org/04v7hvq31', 'https://ror.org/01vf2g217', 'https://ror.org/043mz5j54', 'https://ror.org/03hwe2705', 'https://ror.org/01t8svj65', 'https://ror.org/04g7y4303', 'https://ror.org/02jbv0t02')
ORDER BY auths.author_last_name, auths.author_first_name;
```

Published datasets and published by year
========================================

List of published
```sql
/* get all datasets and their publication date */
SELECT ids.identifier, res.publication_date FROM stash_engine_identifiers ids
JOIN (SELECT max(id) as res2_id, identifier_id FROM stash_engine_resources
  WHERE meta_view = 1
  GROUP BY identifier_id
) as res2
ON ids.id = res2.identifier_id
JOIN stash_engine_resources res
ON res.id = res2.res2_id
WHERE ids.pub_state IN ('published', 'embargoed');
```

Counts of published by year (change embargo or not below)
```sql
SELECT DATE_FORMAT(res.publication_date, '%Y') as year, count(*) as year_count FROM stash_engine_identifiers ids
JOIN (SELECT max(id) as res2_id, identifier_id FROM stash_engine_resources
  WHERE meta_view = 1
  GROUP BY identifier_id
) as res2
ON ids.id = res2.identifier_id
JOIN stash_engine_resources res
ON res.id = res2.res2_id
WHERE ids.pub_state IN ('published', 'embargoed')
GROUP BY DATE_FORMAT(res.publication_date, '%Y');
```

Lists of objects in non-Dryad collections for respository migration
===============================================================
```sql
SELECT ids.identifier, ids.storage_size, res.download_uri, res.title, res.tenant_id, res_count.versions
FROM stash_engine_identifiers ids
JOIN (SELECT max(stash_engine_resources.id) as res2_id, identifier_id FROM stash_engine_resources
  JOIN stash_engine_resource_states sts
  ON stash_engine_resources.`current_resource_state_id` = sts.id
  WHERE tenant_id IN ('dataone', 'lbnl', 'berkeley', 'ucdavis', 'uci', 'ucla', 'ucmerced', 'ucop', 'ucpress', 'ucr', 'ucsb', 'ucsc', 'ucsf')
  AND sts.resource_state = 'submitted'
  GROUP BY identifier_id
) as res2
ON ids.id = res2.identifier_id
JOIN stash_engine_resources res
ON res2.res2_id = res.id
JOIN (SELECT identifier_id, count(id) as versions FROM stash_engine_resources GROUP BY identifier_id) as res_count
ON ids.id = res_count.identifier_id
ORDER BY res.tenant_id, ids.identifier;
```

Lists of items sent to Zenodo and then embargoed afterward (need hiding in Zenodo)
==================================================================================
```sql
SELECT cur_published.identifier_id, cur_published.curation_id as last_publication_id, cur_embargoed.curation_id as last_embargo_id,
ids.*
FROM
	(SELECT res1.identifier_id, max(cur1.id) as curation_id FROM stash_engine_curation_activities cur1
	JOIN stash_engine_resources res1
	ON cur1.resource_id = res1.id
	WHERE cur1.status = 'published'
	GROUP BY res1.identifier_id) as cur_published
JOIN
	(SELECT res2.identifier_id, max(cur2.id) as curation_id FROM stash_engine_curation_activities cur2
	JOIN stash_engine_resources res2
	ON cur2.resource_id = res2.id
	WHERE cur2.status = 'embargoed'
	GROUP BY res2.identifier_id) as cur_embargoed
ON cur_published.identifier_id = cur_embargoed.identifier_id
JOIN stash_engine_identifiers ids
ON cur_published.identifier_id = ids.id
JOIN stash_engine_zenodo_copies zc
ON zc.identifier_id = cur_published.identifier_id
WHERE cur_embargoed.curation_id > cur_published.curation_id
AND zc.state = 'finished';
```
