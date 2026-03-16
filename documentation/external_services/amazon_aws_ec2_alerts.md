
AWS alerts
======================================================================

### RDS production instance

- **RDS Prod - High CPU** - triggered when CPU utilization is greater 80 for 3 data points within 10 minutes
This one is sent for ALARM and OK state
- **RDS Prod - Storage Relatively Low** - Free storage space lower than 5 GB for 1 data points within 25 minutes
- **RDS Prod - High WriteIOPS** - WriteIOPS greater the band (width: 20) for 3 data points within 45 minutes

### EC2 instances
These are set for each machine

- **High CPU - dryad v3 prod 1** - triggered when CPU utilization is greater than 50% for 3 data points within 10 minutes
- **Low Memory - dryad v3 prod 1** - triggered when used memory is greater than 80% for 3 data points within 10 minutes
- **Low Disk Space - dryad v3 prod 1** - triggered when used disk space is greater than 80% for 3 data points within 10 minutes
- **EC2 Prod1 - /data DiskUsage over 80%** - triggered when used disk space is greater than 80% for 1 data point within 5 minutes
- **EC2 Prod1 - DiskUsage over 80%** - triggered when used disk space is greater than 80% for 1 data point within 5 minutes
- **EC2 Prod1 - DiskUsage over 90%** - triggered when used disk space is greater than 90% for 1 data point within 5 minutes
- **prod-1-StatusCheckFailed** - triggered when status check failed greater than 0.99% for 2 data point within 10 minutes

### Emails

- **Email Total Sends / Day** - triggered when sent number is grater than 30000 for 1 data point within 1 day
- **Email Bounce Rate** - triggered when reputation bounce rate grater than 1 for 1 data point within 15 minutes
- **Email Complaint Rate** - triggered when reputation complaint rate grater than 1 for 1 data point within 5 minutes
