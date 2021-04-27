V1 Server
===========

Restarting the v1 Server
------------------------

If the v1 server is having problems, it will typically be indicated by
monitoring reports for the Journal Module, since the Journal Module is
the only portion of that server that is used for production
activities.

Normally, if there is a problem with the v1 server, the cause is a
memory leak within DSpace, and the best method to fix it is to stop
and restart the server.

To verify whether the server is responding, see the UI
at https://v1.datadryad.org , or make a simple call to the journal API
at https://v1.datadryad.org/api/v1/journals/1557-7015

The v1 server can be restarted by:
1. SSH into v1.datadryad.org
2. `bin/tomcat_stop.sh`
3. Verify that the server has stopped by visiting one of the URLs above
4. `bin/tomcat_start.sh`
5. After a few minutes, visit one of the URLs above to verify that the
   server has started.

