#!/bin/bash

#if [ -d /usr/lib/systemd/system ]; then
#    SYSTEMD_ROOT=/usr/lib/systemd/system
#else
#    SYSTEMD_ROOT=/lib/systemd/system
#fi

#daemon_file="$SYSTEMD_ROOT/SBIS3Plugin.service"
daemon_file="/etc/init.d/SBIS3Plugin"
if ! grep -q "Restart=" "$daemon_file"
then
  echo "Adding restart"
#  sed -i '/\[Service\]/a Restart=always\nRestartSec=3600' "$daemon_file"
#  systemctl daemon-reload
  /etc/init.d/SBIS3Plugin restart
else
  echo "Restart present"
fi
