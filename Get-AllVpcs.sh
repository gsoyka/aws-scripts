#!/bin/bash

# Set path to our inventory file
FILE=~/Vagrant/ansible/roles/inventory/vars/data.json

# Erase file
> $FILE

profile="venicegeo-prod"

for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
do
     #echo -e "\nListing VPCs in region:'$region'..."
     aws ec2 describe-vpcs --region $region --profile $profile | jq '.Vpcs[] |  {state: .State, VpcId: .VpcId, cidr: .CidrBlock, IsDefault: .IsDefault}' 
done