
Amazon Web Application Firewall (WAF)
=====================================

The WAF is used to block bots and other undesirable traffic.

Most of our configuration is in the "Web ACLs" section. Note that when you are
viewing pages in the WAF, there are two settings for the region, both at the top
of the screen, and within the main section of the screen.

We apply a basic set of Rules, and scope those rules to only protect the parts
of the system that we want to prevent bots from accessing -- /search and
/downloads.


Debugging WAF issues
=====================

All WAF activity is logged to Cloudwatch. To view logs, select the set of ACLs
(regional-webacl), go to the section for Logging and metrics, and click on the
link to the CloudWatch logs (aws-waf-logs-1-week).

It is often useful to view the Live Tail of the log, and filter the results for
strings you want to see (request types, DOIs, etc.)
