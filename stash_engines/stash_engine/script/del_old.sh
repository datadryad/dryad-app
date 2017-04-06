#!/usr/bin/env bash

# if you run this inside the uploads directory it will clear out any zip files
# and the associated temp files starting with the same number as the zip files.
#
# It should clear out any submitted items no longer needed.

ls *.zip -1 | while read -r line
do
   first=`echo $line | grep -o '^[0-9]*'`
   rm -rf "$first"/
   rm -rf "$first"_*
done