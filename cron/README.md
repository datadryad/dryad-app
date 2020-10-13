# Dryad Cron Jobs

Most of the Dryad Cron jobs are executed via the shell scripts in this directory.

The files deploy with the code (in `apps/ui/current`), but the scheduled crons point to
`/apps/dryad/apps/ui/shared/cron`, so we should re-symlink this directory after
a successful deploy until we can get the crontab changed in puppet.

## Frequencies:

Cron jobs run on one of the following schedules:
- every_1.sh <-- Every minute for checking the OAI feed for publications
- every_5.sh <-- Every 5 minutes
- daily.sh <-- Every day at 12:00
- weekly.sh <-- Every Sunday at 21:00
- monthly.sh <- On the 20th at 19:00

Cron MUST pass in the environment as an argument when executing the scripts! For example: `/apps/dryad/apps/ui/shared/cron/daily.sh development`


## Adding a new Cron task:

Add your task as a new line to one of these shell scripts and then redeploy the app via Capistrano. If you need to incorporate a new frequency (e.g. every 30 minutes) you will need to add the new shell script and then coordinate with the team who manages puppet to have the corresponding line added to the crontab.

## Cron tasks:

example crontab

```shell
# Run jobs every 5 minutes
*/5 * * * * /apps/dryad/apps/ui/shared/cron/every_5.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1

# Run the jobs at noon each day
00 12 * * * /apps/dryad/apps/ui/shared/cron/daily.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1

# Run the jobs every Sunday at 21:00
00 21 * * 0 /apps/dryad/apps/ui/shared/cron/weekly.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1
```