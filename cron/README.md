# Dryad Cron Jobs

Most of the Dryad Cron jobs are executed via the shell scripts in this directory.

The files deploy with the code (in `apps/ui/current`), but the logs and shared items are in
`/apps/dryad/apps/ui/shared/cron`.

## Frequencies:

Cron jobs run on one of the following schedules:
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
*/5 * * * * /apps/dryad/apps/ui/current/cron/every_5.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1

# Run the jobs at noon each day
00 12 * * * /apps/dryad/apps/ui/current/cron/daily.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1

# Run the jobs every Sunday at 21:00
00 21 * * 0 /apps/dryad/apps/ui/current/cron/weekly.sh stage >> /apps/dryad/apps/ui/shared/cron/logs/cron.log 2>&1
```

##counter-processor move to new server (require for counter weekly cron to work after move)
- Set up ssh so you can scp files
- Do commands like these after checking out the counter processor from github on the new server
  and being in the same directory on the new server.
  
```bash
scp <user>@<domain>:~/apps/counter/counter-processor/config/config.yaml .
scp <user>@<domain>:~/apps/counter/counter-processor/config/secrets.yaml .
cd ../maxmind_geoip
scp <user>@<domain>:~/apps/counter/counter-processor/maxmind_geoip/* .
cd ..
mkdir state
cd state
scp <user>@<domain>:~/apps/counter/counter-processor/state/* .
```

Also copy over any old finished reports
```bash
cd /apps/dryad/apps/ui/shared/cron/counter-json
scp <user>@<domain>:/apps/dryad-prd-shared/json-reports/* .
```