#!/bin/sh

# Lists the IP addresses that have downloaded the most in the most recent log file, and their frequency

echo "=== Heavy downloads of individual files ==="
grep "downloads/file" /var/log/httpd/datadryad.org-access_log | awk '{ print $1 } ' | sort | uniq -c |sort -r | head

echo "=== Heavy downloads of ZIP files ==="
grep "downloads/zip" /var/log/httpd/datadryad.org-access_log | awk '{ print $1 } ' | sort | uniq -c |sort -r | head

