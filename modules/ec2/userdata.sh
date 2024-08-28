#!/bin/bash

#installs ansible and hashicorp valut packages
pip3.11 install ansible hvac 2>&1 | tee -a /opt/userdata.log
#note shell variables are accessed with ${}
ansible-pull -i localhost, -U https://github.com/prashanthkp3103/Latest-Ansible-Roboshop main.yml -e env=${env} -e role_name=${role_name} -e vault_token=${vault_token} 2>&1 | tee -a /opt/userdata.log