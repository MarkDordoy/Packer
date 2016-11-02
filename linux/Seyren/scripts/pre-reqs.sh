#!/bin/bash -x

set -e # Exit immediately on failure
set -o verbose

sudo sed -i '0,/enabled=0/s/enabled=0/enabled=1/' /etc/yum.repos.d/epel.repo
sudo mv ~/mongodb-org-3.2.repo /etc/yum.repos.d/mongodb-org-3.2.repo
sudo yum update -y
sleep 15
sudo yum install -y mongodb-org
sudo service mongod start
sudo chkconfig mongod on
sudo yum install nginx -y 
sudo chkconfig nginx on
sudo yum install tomcat7 -y
sudo yum install tomcat7-webapps -y
sudo chkconfig tomcat7 on
sudo yum install ansible -y
sudo yum install git -y