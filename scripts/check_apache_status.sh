#!/bin/bash

STATUS=$(systemctl is-active httpd)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ONLINE_FILE="/mnt/efs/<My_Name>/apache_status_online.txt"
OFFLINE_FILE="/mnt/efs/<My_Name>/apache_status_offline.txt"

if [ "$STATUS" = "active" ]; then
    echo "$TIMESTAMP Apache ONLINE" > "$ONLINE_FILE"
    [ -e "$OFFLINE_FILE" ] && rm "$OFFLINE_FILE"
else
    echo "$TIMESTAMP Apache OFFLINE" > "$OFFLINE_FILE"
    [ -e "$ONLINE_FILE" ] && rm "$ONLINE_FILE"
fi