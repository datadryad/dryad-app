
Reporting
==============


Shopping Cart Report
-----------------------

The "Shopping Cart Report" is a report of how/when we collected
payment for individual datasets.

Run it with a command like:
```
RAILS_ENV=production bundle exec rake identifiers:shopping_cart_report YEAR_MONTH=2020-01
```


Make Data Count / Counter Report
---------------------------------

The "Make Data Count" report runs automatically from the production
server. It uses a mix of python scripts and rake tasks to gather usage
statistics, send them to DataCite, and record copies in our database.

The main control script is `cron/counter.sh`



