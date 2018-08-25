#!/bin/bash

mydir="../dryad-config"
CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $CURRENTDIR

if [ ! -d $mydir ]; then
	echo "Copying configuration files:"
	mkdir -p $mydir/config
	rsync -av $CURRENTDIR/dryad-config-example/ $mydir/config
fi

echo "Symlinking..."

cd $mydir
CONFIGDIR="$( pwd )"
len=$((${#CONFIGDIR} + 1))
cd $CURRENTDIR

if [ ! -e $CURRENTDIR/config/tenants ]; then
	echo "symlinking tenants"
	ln -s $CONFIGDIR/config/tenants/ $CURRENTDIR/config/tenants
fi

ls $CONFIGDIR/config/*.yml | while read -r line
do
    shortfn=${line:len}
    fullfn="$line"
	if [ -h $shortfn ]; then
		echo "file $shortfn is already symlinked" 
	else
		echo "symlinking $shortfn"
		ln -s "$fullfn" "$shortfn"
	fi
done
