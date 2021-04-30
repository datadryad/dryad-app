V1 Server
===========

The v1 server is no longer in use. Its functionality has been moved into the v2
server. However, it may still be useful to look at the v1 server for reference
on some items.

Starting the v1 Server
-----------------------

To get the machine running:
1. Login to a Dryad account in the AWS web interface.
2. Go to the EC2 section.
3. Select "Instances" from the menu.
4. Select the server "prod-solr", and if it is not running, Start Instance.
4. Select the server "prod", and if it is not running, Start Instance.

Wait a few minutes, and verify whether the server is responding 
at `https://v1.datadryad.org` 

If the server is not responding:
1. SSH into v1.datadryad.org
2. `bin/tomcat_stop.sh`
4. `bin/tomcat_start.sh`
5. After a few minutes, visit one of the URLs above to verify that the
   server has started.

Big caveats:
- The startup process can take up to 10 minutes. You can watch the log file at
  `/opt/dryad/logs/dspace.log` to verify whether there is activity
- The homepage at `https://v1.datadryad.org` may show an error message, below
  the Dryad logo. If it does, this likely means that the server was not able to
  obtain some of the information it needed to render the homepage, BUT the rest
  of the server is probably still running without problems. The most common
  problem with rendering data on the homepage is a problem with the cached data
  that is used for building the page. To fix, delete the contents of the cache
  in `/opt/dryad/cached`

Stopping the v1 server
-----------------------

1. Login to a Dryad account in the AWS web interface.
2. Go to the EC2 section.
3. Select "Instances" from the menu.
4. Select the server "prod-solr", and if it is running, Stop Instance.
4. Select the server "prod", and if it is running, Stop Instance.


Using the v1 server
-------------------

Normally, you will need to login through the v1 server's web UI.

The Postgres database can be accessed from the command line:
1. SSH into v1.datadryad.org
2. sudo into the `ubuntu` account
3. run the script `pc` (for Postgres Client)


Archived server contents
------------------------

Machine image -- In AWS EC2, there is a "snapshot" of the server called "v1
production server at decommissioning".

Metadata -- In addition to the "live" Postgres instance described above, there
is an export of the database contents in AWS S3, in
`dryad-backup/databaseBackups/dryadDBlatest.sql`

Data files -- The data files are archived in S3's Glacier storage, in the S3
bucket `dryad-assetstore-east`. Note that these bitstreams will not make any
sense unless you have the corresponding metadata from the database.
