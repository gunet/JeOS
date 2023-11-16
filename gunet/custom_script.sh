#!/bin/bash

systemctl enable acpid.service

sed -i "/Port 22/aPort 65432" /etc/ssh/sshd_config

#rm -r /var/log/installer;

exit 0;
								
