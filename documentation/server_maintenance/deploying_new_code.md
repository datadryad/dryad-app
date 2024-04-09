
Deployment of code to the Dryad servers
=========================================

Steps to deploy a new release to stage/production
-------------------------------------------------

Deploying to the Dryad production system requires several steps. These
are elaborated below or in supporting documents as noted.

Steps in a production deploy:
1. Tag the code for release
2. Deploy to stage - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 
3. Test any new functionality on stage
4. Suspend jobs that transfer content to permanent storage and Zenodo
5. Deploy to prod - For each server, remove it from the ALB, perform
   the deploy, and return it to the ALB. 
6. Resume repository and Zenodo submissions

Creating tags for deployment
---------------------------------

You may deploy from a tag as well as a branch.

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


De/Re-Registering Servers from the ALB
---------------------------------------

To register and de-register servers from the ALB, use the AWS console.

<!-- CHECK ALL AGAINST NEW SERVERS!!

Suspending and re-enabling jobs around deployment
-------------------------------------------------

Dryad servers send datasets to permanent storage and Zenodo using job
queues. These queues should be suspended during a redeploy to ensure
a dataset is not in the process of being transferred when the code is
changed out.

Briefly, a little while ahead:
- On 2c, run `~/bin/long_jobs.dryad drain`.  It touches the defer_jobs.txt and hold-submissions.txt files in `~/apps/ui/releases`.
- On 2a, touch `~/apps/ui/releases/hold-submissions.txt`

Deploy

After
- Run `~/bin/long_jobs.dryad restart` on 2c.
- Remove `~/apps/ui/releases/hold-submissions.txt` on 2a.
- Reset the servername in the repo_queue_state table for any jobs being held to match the server name you're looking at in the UI.
- Click "Restart submissions which were shut down gracefully."  It'll send them through again.

For information on starting/stopping these transfers, see:
- [Zenodo extra copies](../zenodo_integration/delayed_jobs.md)


Setting a server to "Maintenance Mode"
--------------------------------------

Put a `maintenance.html` file in the vhost's htdocs directory (document
root). If it is there maintenance will be shown to outside IP
addresses and not to us. You'll need to do on both servers for
maintenance on both.

Maintenance mode shows outside IP addresses a maintenance page served
by Apache, while our internal IP addresses have traffic passed through
and are able to see the application served by Passenger.

-->