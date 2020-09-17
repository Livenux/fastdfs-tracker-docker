#!/bin/bash

echo "\nChange FDFS Storage configure file\n"
set -x
sed -i "s/^#tracker_server.*$/${TRACKER_SERVER}/" /etc/fdfs/storage.conf
sed -i "s/^#tracker_server.*$/${TRACKER_SERVER}/" /etc/fdfs/client.conf
sed -i "s/http.domain_name.*$/http.domain_name=$WEB_DOMAIN/" /etc/fdfs/storage.conf

echo "\nStart FDFS tracker Server.\n"

/usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf
sleep 5
tail -f  /var/fdfs/logs/trackerd.log
