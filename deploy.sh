#!/bin/bash

set -e

cd terraform 

echo "terraform init"
terraform init

echo "terraform apply"
terraform apply -auto-approve

echo "Mostrar las ips de las instancias"
IPS=$(terraform output -json public_ips | jq -r '.[]')

echo "buscando ips de las instancias"
echo "$IPS"

echo "esperar a que se creen las instancias"
sleep 10

cd ..
cd ansible
echo "ansible-playbook webserver"
ansible-playbook site.yml -i aws_ec2.yml

echo "ansible-playbook database"
ansible-playbook site2.yml -i aws_ec2.yml

echo "Terminado satisfactoriamente"
