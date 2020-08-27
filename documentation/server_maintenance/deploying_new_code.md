
Deployment of code to the Dryad servers
=========================================

Code deployment with Capistrano
-------------------------------

Most of the servers have a `~/tools/deploy/dryad-app` directory, which
contains a copy of the codebase suitable for launching the deployment
process. However, the deployment process will place the resultant
files into `~/apps/ui/current`.

To deploy with capistrano, you must be in the deploy directory, then:
```
cap <capistrano deploy environment> deploy BRANCH="<branch or tag>"
```

The deploy script uses the same branch or tag for both git
repositories, the main `dryad-app` and the private
`dryad-config`. That means if you tag on one repository, you should
tag both so they have matching tags.

Note that there are both machine-level and environment-level
capistrano environment settings for convenience. `stage1` will only
deploy to the first stage server, `stage2` will only deploy to the
second, `stage` will deploy to both. The other way to do this is to
set an environment variable SERVER_HOSTS (with all domain names
separated by spaces) and it will attempt deploying to the domain names
you specify.  I can never remember the long 12-part domain names CDL
sets up without copy-pasting them, though.

Remember, in order for capistrano to work, it must SSH in to servers.
That means that the public key for any computer you want to deploy
from must be added to the authorized_keys for the dryad account on the
server you want to deploy to. This also means that if you want to
deploy locally on a machine you must add the public key to the
authorized keys on the same computer because it still uses ssh.


Steps to deploy a new release to stage/production
-------------------------------------------------

Deploying to the Dryad production system requires several steps. These
are elaborated below or in supporting documents as noted.

Steps in a production deploy:
1. Tag the code for release
2. Deploy to stage - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 
3. Test any new functionality on stage
4. Suspend jobs that transfer content to Merritt and Zenodo
5. Deploy to prod - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 
6. Resume Merritt/Zenodo submissions

Creating tags for deployment
---------------------------------

Capistrano allows deploying from a tag as well as a branch. In either
case, both `dryad-app` and `dryad-config` repos need to have that same
branch or tag on the origin server (github) to work properly. So, for
example, if you tag something as `v0.1.1` in dryad-app then you should
create the same tag in the other repositories since it will use the
same tag across the repositories for all parts of the application.

[Git-Basics-Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
gives some information about how to tag. For this project, there are a
few guidelines.

Create a tag:
```
# first pull tags like below to be sure you're up to date
git pull origin --tags
git tag -a <version>
# or git tag -a <version> -m '<my message goes here>' to tag and supply a message all at once.
```
Push the tag back to the remote repository:
```
git push origin --tags
```

After putting the tags on all the repositories and pushing them, you
can deploy from a tag instead of a branch name if you prefer, as
described above. This saves having to do a merge into an environment
such as stage if you know that the current state is the version you
want to tag and deploy.  You can list tags on a repo with `git tag`.

If you need to delete a tag and retag then you can remove a tag by:
```
git tag -d <tag-name>
git push --delete origin <tag-name>
```

After creating tags, you will usually want to create an official
"release" along with release notes in the GitHub user interface.

Suspending jobs for deployment
------------------------------

Dryad servers send datasets to Merritt and Zenodo using job
queues. These queues should be suspended during a redeploy to ensure
a dataset is not in the process of being transferred when the code is
changed out.

For information on starting/stopping these transfers, see:
- [Zenodo extra copies](../zenodo_integration/delayed_jobs.md)
- [Interactions with Merritt](merritt.md)


De/Re-Registering Servers from the ALB
---------------------------------------

When you are logged in to a production server, you can use convenience
scripts to manage the ALB. Sample scripts for the staging environment
are shown below, but `stg` can be replaced with `prd` to manage the
production ALB as well:

```
/apps/dryad/alb/alb_stg_check_status.sh
/apps/dryad/alb/alb_deregister.sh stg a
/apps/dryad/alb/alb_deregister.sh stg c
/apps/dryad/alb/alb_register.sh stg a
/apps/dryad/alb/alb_register.sh stg c
```

If you are logged into the ops server, see these notes :

```
$ ssh uc3-aws2-ops.cdlib.org
$ sudo su - uc3aws

# our albs are named uc3-dryad-prd-alb or uc3-dryad-stg-alb

######## stage ########

### deregister
load-balancer.bash uc3-dryad-stg-alb deregister uc3-dryaduix2-stg-2a
load-balancer.bash uc3-dryad-stg-alb deregister uc3-dryaduix2-stg-2c

### reregister
load-balancer.bash uc3-dryad-stg-alb register uc3-dryaduix2-stg-2a
load-balancer.bash uc3-dryad-stg-alb register uc3-dryaduix2-stg-2c


######## production ########

### deregister
load-balancer.bash uc3-dryad-prd-alb deregister uc3-dryaduix2-prd-2a
load-balancer.bash uc3-dryad-prd-alb deregister uc3-dryaduix2-prd-2c

### reregister
load-balancer.bash uc3-dryad-prd-alb register uc3-dryaduix2-prd-2a
load-balancer.bash uc3-dryad-prd-alb register uc3-dryaduix2-prd-2c
```

Checking for Chunked Upload in the UI
-------------------------------------

The other process that is long-running might a a user upload to the
UI. The user uploads hit the path /stash/file_uploads with a post
request for each segment of the file. You can grep the logs to see if
there are a lot of them happening in the past hour or past 10 minutes
or some other time you can grep for. Restarting in the middle of an
upload will stall that user's upload. They could delete and upload
again, but it's better to not interrupt them if possible to wait for
them to finish.


Setting a server to "Maintenance Mode"
--------------------------------------

Put a `maintenance.html` file in the vhost's htdocs directory (document
root). If it is there maintenance will be shown to outside IP
addresses and not to us. You'll need to do on both servers for
maintenance on both.

Maintenance mode shows outside IP addresses a maintenance page served
by Apache, while our internal IP addresses have traffic passed through
and are able to see the application served by Passenger.
