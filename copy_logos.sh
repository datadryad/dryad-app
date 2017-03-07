#!/bin/bash

# originally going to symlink images, but causes problems so, doing this as a copy instead  :-)  Why the script is odd

find 'app/assets/images/tenants' -name '*.png' -o -name '*.jpg' -o -name '*.svg' | while read -r line
do
	publicfn=public/images/$(basename $line)
  cp "$line" "$publicfn"
done