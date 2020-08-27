
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
