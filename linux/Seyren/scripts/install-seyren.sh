#!/bin/bash -x

set -e # Exit immediately on failure
set -o verbose

sudo wget https://github.com/scobal/seyren/releases/download/1.5.0/seyren-1.5.0.war -O /var/lib/tomcat7/webapps/ROOT.war
sudo chmod 0664 /var/lib/tomcat7/webapps/ROOT.war