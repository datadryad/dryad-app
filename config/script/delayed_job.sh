#!/bin/bash

# need to change the environment in this file

# For documentation of INIT INFO, see:
# http://refspecs.linuxbase.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/initscrcomconv.html

# See https://github.com/collectiveidea/delayed_job/wiki/Delayed-job-command-details for delayed job options

### BEGIN INIT INFO
# Provides: delayed_job.dryad
# Required-Start: $local_fs $network $remote_fs
# Should-Start: ypbind nscd ntpd xntpd sshd
# Required-Stop: $local_fs $network $remote_fs
# Should-Stop: sshd
# Default-Start: 2 3 5
# Default-Stop: 0 1 2 6
# Description: start and stop delayed_job as dryad
# Description: This script is used for *both* the system startup/shutdown
#  (running as root) as well as stop/start by the dryad role account,
#  by checking for EUID==0 (root).
### END INIT INFO

# This script is managed by Puppet. If you change this, be sure to update the
# copy at uc3puppet@cdl-aws-puppet.cdlib.org:/apps/puppet/environments/uc3 and
# push it to the git main branch

ROLE_ACCT=dryad

PROG=delayed_job.dryad

# Source function library. There are 2 identical copies of this on the AWS
# systems I have seen: one referenced below, and /etc/rc.d/init.d/functions
. /etc/init.d/functions

# Is this being run by root, or the role account?
if [ "$EUID" != "0" ]; then
    # Presumably we are running as the role account. In any case, we are not
    # root, so cannot create/remove the lockfile.

    # Set up path and other env vars for rails, same as original passenger.erb
    export RAILS_ENV='development'
    export RAILS_ROOT=/dryad/apps/ui/current

    # Don't touch $PATH or $HOME of root!

    # JV, 2016-09-15: Shouldn't this be set up already?!?
    export HOME=/apps/dryad


    # Build the $PATH, from the tail first.
    PATH=/bin
    # Minimal pathmunge function, so I don't have to repeat the directory.
    pathmunge () {
	# If the directory exists, add it at the front of the PATH.
        [ -d "$1" ] && PATH="$1:$PATH"
    }
    pathmunge $HOME/.rvm/bin
    pathmunge /usr/X11R6/bin
    pathmunge /usr/bin/X11
    pathmunge /sbin
    pathmunge /usr/bin
    pathmunge /usr/local/bin
    pathmunge /opt/csw/bin
    pathmunge $HOME/apps/mysql/bin
    pathmunge $HOME/local/lib
    pathmunge $HOME/local/bin
    pathmunge $HOME/bin
    export PATH
    export RUBYPATH=$HOME/local/bin

    export cap=$HOME/local/bin/cap
    export bundle=$HOME/local/bin/bundle

    case "$1" in
	start)
	    ( cd $RAILS_ROOT && $bundle exec bin/delayed_job -n 3 start )
	    ;;
	stop)
	    ( cd $RAILS_ROOT && $bundle exec bin/delayed_job -n 3 stop )
            ;;
	restart)
	    ( cd $RAILS_ROOT && $bundle exec bin/delayed_job -n 3 restart )
            ;;
	status)
	    ( cd $RAILS_ROOT && $bundle exec bin/delayed_job -n 3 status )
            ;;
	*)
            echo "Usage: $0 {start|stop|restart|status}"
            exit 1
            ;;
    esac
else
    # I am [G]root! sudo to the role account and do whatever was requested.
    LOCKFILE=/var/lock/subsys/${PROG}
    SU=/bin/su

    case "$1" in
	start)
	    # sudo to the role account and run the command...
	    $SU - $ROLE_ACCT -c "$0 $1"
	    # ...then create the lockfile
	    touch ${LOCKFILE}
	    ;;
	stop)
	    # sudo to the role account and run the command...
	    $SU - $ROLE_ACCT -c "$0 $1"
	    # ...then remove the lockfile
	    rm -f ${LOCKFILE}
	    ;;
	restart)
	    echo "'$1' must be run under the role account"
	    exit 1
            ;;
	status)
	    echo "'$1' must be run under the role account"
	    exit 1
            ;;
	*)
            echo "Usage: $0 {start|stop|restart|status}"
            exit 1
            ;;
    esac
fi

exit 0
