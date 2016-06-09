#! /bin/sh

# Install this file in ~dash2/init.d, and make sure RAILS_ENV is correct below.

export RAILS_ENV=development

appDir=$(readlink -f $HOME/apps/ui/current)
delayed_job=${appDir}/bin/delayed_job

case "$1" in
    stop)
        ${delayed_job} stop
        ;;
    start)
        ${delayed_job} start
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
exit 0
