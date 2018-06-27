#!/bin/bash

mydir="../dryad-config"
len=$((${#mydir} + 1))
CURRENTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $CURRENTDIR

echo $CURRENTDIR

mkdir -p config/tenants


find "$mydir" -name '*.yml' | while read -r line
do
	shortfn=${line:len}
        fullfn="$CURRENTDIR/$line"
	if [ -h $shortfn ]; then
               echo "file $shortfn is already symlinked" 
            else
               echo "symlinking $shortfn"
               ln -s "$fullfn" "$shortfn"
            fi
done
	
