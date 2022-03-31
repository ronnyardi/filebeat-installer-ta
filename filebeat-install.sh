#!/bin/bash

VERSION="7.17.0"

echo -e "Filebeat akan diunduh dan dijalankan pada path /opt/filebeat/7.17.0/ \n"
echo -e "Starting..\n"
mkdir -p /opt/filebeat/$VERSION/certs
cp logstash-forwarder.crt /opt/filebeat/$VERSION/certs && cd /opt/filebeat

echo -e "Downloading Filebeat version 7.17.0 ...\n"
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$VERSION-linux-x86_64.tar.gz --show-progress
echo -e "Downloading Completed..\n"

# Extract
sleep 1
mkdir -p $VERSION
FILENAME=$(ls -tr *.tar.gz | head -1)
tar -xf $FILENAME -C $VERSION --strip-components=1
rm -fr $FILENAME
cd $VERSION

# Filebeat Config
cat <<END >filebeat.yml
filebeat.inputs:
- type: filestream
  enabled: true
  paths:
    - filename.log
  tags: ["testTag"]

filebeat.config.modules:
  path: /opt/filebeat/VERSION/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1

output.logstash:
  hosts: ["35.240.140.173:5044"]
  ssl.certificate_authorities: ["/opt/filebeat/VERSION/certs/logstash-forwarder.crt"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
END

sleep 1
echo -e "Configuring the Agent...?"
sleep 2
read -e -p 'Type for which files that need to be take in. [E.x. /var/log/syslog.log] => ' PATH1
if [[ $PATH1 == *"/"* ]]; then
	PATH1=${PATH1//\//\\\/}
fi
/bin/sed -i s/filename.log/$PATH1/g filebeat.yml
echo -e " "

sleep 1
#read -e -p 'Type the TAGS name that you need to add in for the above mentioned logs. [E.x. testTag] => ' TAG1
#/bin/sed -i s/testTAG/$TAG1/g filebeat.yml
/bin/sed -i s/VERSION/$VERSION/g filebeat.yml
#echo -e " "

# systemD unit file
echo -e "Setting up systemD service files.."
cat <<END >/etc/systemd/system/filebeat.service
[Unit]
Description=Filebeat
After=network.target

[Service]
Type=simple
Restart=always
User=root
Group=root
WorkingDirectory=/opt/filebeat/VERSION
ExecStart=/opt/filebeat/VERSION/filebeat -c /opt/filebeat/VERSION/filebeat.yml

[Install]
WantedBy=multi-user.target
END

# change the systemd file variables
sleep 1
/bin/sed -i s/VERSION/$VERSION/g /etc/systemd/system/filebeat.service

echo -e " "
echo "Starting up the filebeat.service"
systemctl daemon-reload
sleep 2
systemctl enable filebeat.service
systemctl start filebeat.service
systemctl is-active filebeat.service >/dev/null 2>&1 && echo "Congradulations.. Filebeat is now starting & sending logs" || echo "Something is Wrong.! Check the configuration"
