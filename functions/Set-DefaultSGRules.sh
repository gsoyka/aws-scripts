#!/bin/bash

function Set-DefaultSGRules {
	# Define aws cli profile to use
	profile=$1
	region=$2
	
	echo -e "\nConfiguring default security groups in: $region"
	
	# Get Default Security Group for region
	sg=$(aws ec2 describe-security-groups --profile $profile --region $region --group-names default | jq --raw-output '.SecurityGroups[] | .GroupId')
	echo "Region's Default SG ID: $sg"
	
	# Remove inbound rule
	aws ec2 revoke-security-group-ingress --profile $profile --region $region --group-id $sg --protocol all --cidr 0.0.0.0/0 --port all --source-group $sg
	# Remove outbound rule
	aws ec2 revoke-security-group-egress --profile $profile --region $region --group-id $sg --protocol all --cidr 0.0.0.0/0 --port all 

}