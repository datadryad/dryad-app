# Dryad Cron Jobs

Most of the Dryad Cron jobs are executed via the shell scripts in this directory.

The files deploy with the code (in `/home/ec2-user/deploy/current`), but the logs and shared items are in
`/home/ec2-user/deploy/shared/cron`.

## Frequencies:

Cron jobs run on one of the following schedules:
- every_5.sh <-- Every 5 minutes
- daily.sh <-- Every day at 12:00
- weekly.sh <-- Every Sunday at 21:00
- monthly.sh <- On the 20th at 19:00

Cron MUST pass in the environment as an argument when executing the scripts! For example: `/home/ec2-user/deploy/shared/cron/daily.sh development`


## Adding a new Cron task:

Add your task as a new line to one of these shell scripts and then redeploy the app via Capistrano. If you need to incorporate a new frequency (e.g. every 30 minutes) you will need to add the new shell script and then coordinate with the team who manages puppet to have the corresponding line added to the crontab.

## Cron tasks:

Cron jobs are configured to run using systemd timers. The `*.service` and `*.timer` files need to be placed in `/etc/systemd/system/`.
Example files are [here](files)

Every systemd service needs to be enabled and started using `systemctl enable <service>` and `systemctl start <service>`.

```shell
# Start jobs that run hourly
systemctl start cron_hourly

# Enable jobs that run hourly
systemctl enable cron_hourly
```

Make sure to edit the `*.service` files to specify the proper Rails environment.

After changing any of the files in `/etc/systemd/system/`, you need to reload the systemd daemon using `systemctl daemon-reload`.

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
cd /home/ec2-user/deploy/shared/cron/counter-json
scp <user>@<domain>:/apps/dryad-prd-shared/json-reports/* .
```
