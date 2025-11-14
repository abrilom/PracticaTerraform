#!/bin/bash

set -e

cd terraform 



echo "terraform apply"
terraform apply -auto-approve

echo "making EC2 instances"
IPS=$(terraform output -json public_ips | jq -r '.[]')

echo "buscando ips de las instancias"
echo "$IPS"

cd ..
cd ansible
echo "ansible-playbook"
ansible-playbook site.yml -i aws_ec2.yml

echo "Terminado satisfactoriamente"
