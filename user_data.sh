#!/bin/bash
# user_data.sh
# This runs on first boot to install and start Nginx, and write a test page.

set -euxo pipefail                         # safer bash: stop on errors, echo commands

yum update -y                              # update packages on Amazon Linux 2
amazon-linux-extras install -y nginx1      # install nginx from Amazon extras
systemctl enable nginx                     # start nginx on boot
echo "Hello from ${PROJECT_NAME:-demo-vpc}" > /usr/share/nginx/html/index.html
systemctl start nginx                      # start nginx now
