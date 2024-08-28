#!/bin/bash

pip3.11 install ansible 2>&1 | tee -a /opt/userdata.log
ansible-pull -i localhost, -U https://github.com/prashanthkp3103/Latest-Ansible-Roboshop.git main.yml -e env=$env -e role_name=$role_name main.yml -e
vault_token=$vault_token 2>&1 | tee /opt/userdata.log
