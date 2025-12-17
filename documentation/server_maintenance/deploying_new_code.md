Patching and deployment
=======================

Patching
--------
Patch all instances: dev, stage, and production, and all SOLR instances. If an instance needs patching, you will see a message like the following when you log on:

```
Updates Information Summary: available
    25 Security notice(s)
        11 Important Security notice(s)
        14 Medium Security notice(s)
Security: kernel-6.1.119-129.201.amzn2023.x86_64 is an installed security update
Security: kernel-6.1.77-99.164.amzn2023.x86_64 is the currently running version

   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.  _/
         _/ _/
       _/m/'
```


1. Run `sudo dnf upgrade`
2. Agree to any google chrome/mysql downloads and upgrades.
3. You should see a message like the following:
```
======================================================================================
WARNING:
  A newer release of "Amazon Linux" is available.

  Available Versions:

  Version 2023.6.20250123:
    Run the following command to upgrade to 2023.6.20250123:

      dnf upgrade --releasever=2023.6.20250123

    Release notes:
     https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes-2023.6.20250123.html

======================================================================================
```
4. Run the command for the latest version upgrade listed, with sudo. So for example: `sudo dnf upgrade --releasever=2023.6.20250123`
5. Agree to the download and wait for it to complete.
6. Run `dnf needs-restarting -r`
7. If you do not see the message, `Reboot is required to fully utilize these updates.`, run `sudo update-motd`
8. Otherwise, the instance must be rebooted. For non-SOLR instances, **Make sure the instance is first deregistered from the load balancer target groups**. You can also do a deployment while the instance is not registered (see below).
9. For SOLR instances, after rebooting, make sure SOLR is running again with 
```
cd solr-9.7.0/
bin/solr start
```

Steps to deploy a new release to stage/production
-------------------------------------------------

Deploying to the Dryad production system requires several steps. These
are elaborated below or in supporting documents as noted.

Steps in a production deploy:
1. Update the date for generated assets, so browser caching works properly
2. Tag the code for release and create release notes
3. Deploy to stage - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 
4. Test any new functionality on stage
5. Deploy to prod - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 

Date for generated assets
-------------------------

Update config/initializers/assets.rb to contain the current date for the `assets.version`


Creating tags for deployment
----------------------------

You may deploy from a tag as well as a branch.

You may create a tag through the following commands. You can also create a tag in the "Choose a tag" dropdown, when creating a release and release notes by clicking the "Draft a new release" button on the [github user interface](https://github.com/datadryad/dryad-app/releases).

[Git-Basics-Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
gives some information about how to tag.

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

You can list tags on a repo with `git tag`.

If you need to delete a tag and retag then you can remove a tag by:
```
git tag -d <tag-name>
git push --delete origin <tag-name>
```

De/Re-Registering Servers from the ALB
---------------------------------------

To register and de-register servers from the ALB, use the AWS console. You will
go into the <a href="https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#TargetGroups:">EC2
Target Groups</a>, select the group you want to work with, and update the status
of the individual servers.


Deploying
---------

On the deregistered instance, run the following:

```
deploy_dryad.sh <tag-name or branch>
puma_restart.sh
sudo systemctl restart sidekiq
```

