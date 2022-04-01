#!/bin/bash

echo -e "Uninstalling Filebeat... \n"
rm -r /opt/filebeat/
systemctl stop filebeat.service
rm -r /etc/systemd/system/filebeat.service
sleep 2

echo "Filebeat successfully uninstalled \n"
