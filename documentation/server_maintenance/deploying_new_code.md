
Deployment of code to the Dryad servers
=========================================

Code deployment with Capistrano
-------------------------------

Dryad servers store a "working" copy of the code in `~/dryad-app`, and deploy to
`~/deploy`.

To deploy with capistrano, use the `deplo_dryad.sh` script, like:
```
deploy_dryad.sh <branch or tag>
```

Although Capistrano is able to deploy remotely, we do not have the servers
configured for this setup. Each server is able to SSH to itself, solely for the
purpose of running the deploy process.


Steps to deploy a new release to stage/production
-------------------------------------------------

Deploying to the Dryad production system requires several steps. These
are elaborated below or in supporting documents as noted.

Steps in a production deploy:
1. Tag the code for release
```
git pull origin --tags
git tag -a <version>
git push origin --tags
```
2. Deploy to stage - For each server, login to the server and:
```
deploy_dryad.sh <version>
puma_restart.sh
delayed_job_restart.sh
status_updater_restart.sh
```
3. Test any new functionality on stage
4. On production servers, pause jobs that transfer content to permanent storage and Zenodo
```
touch ~/deploy/releases/hold-submissions.txt
touch ~/deploy/releases/defer_jobs.txt
```
5. Wait until all processing jobs have completed
6. Deploy to prod - For each server:
```
deploy_dryad.sh <version>
puma_restart.sh
rm ~/deploy/releases/hold-submissions.txt
rm ~/deploy/releases/defer_jobs.txt
delayed_job_restart.sh
status_updater_restart.sh
```
7. If everything is ok, resend any submissions that were held during the deploy
   process.
   

For more information on the delayed_job processing:
- [Zenodo extra copies](../zenodo_integration/delayed_jobs.md)


De/Re-Registering Servers from the ALB
---------------------------------------

To register and de-register servers from the ALB, use the AWS console.


Setting a server to "Maintenance Mode"
--------------------------------------

Put a `maintenance.html` file in the vhost's htdocs directory (document
root). If it is there maintenance will be shown to outside IP
addresses and not to us. You'll need to do on both servers for
maintenance on both.

Maintenance mode shows outside IP addresses a maintenance page served
by Apache, while our internal IP addresses have traffic passed through
and are able to see the application served by Passenger.
