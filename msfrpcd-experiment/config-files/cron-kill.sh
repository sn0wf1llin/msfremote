#!/bin/bash

mkdir -p /var/spool/cron
touch /var/spool/cron/root
/usr/bin/crontab /var/spool/cron/root
echo "10 * * * * root shutdown -h now" >> /var/spool/cron/root && crontab -u root -l
