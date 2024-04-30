#!/bin/sh

# Lists the IP addresses that have downloaded the most in the most recent log file, and their frequency

echo "=== Heavy downloads of individual files ==="
grep "downloads/file" /home/ec2-user/deploy/shared/log/v3_production.log | awk '{ print $6 } ' | sort | uniq -c |sort -r | head

echo "=== Heavy downloads of ZIP files ==="
grep "downloads/zip" /home/ec2-user/deploy/shared/log/v3_production.log | awk '{ print $6 } ' | sort | uniq -c |sort -r | head


