#!/bin/bash

# Define regions we want to exclude (to address manually)
used_regions=(
	us-east-1
	us-west-1
	us-west-2
)

# Define aws cli profile to use
profile="venicegeo"

# Loop over all EC2 regions
for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
do
	if [[ ${used_regions[*]} =~ $region ]]
	then
		echo -e "\n$region is in Used Regions; Ignoring"
	else
		echo -e "\n$region is not in Used Regions"
		
		# Get Default Security Group for region
		sg=$(aws ec2 describe-security-groups --profile $profile --region $region --group-names default | jq --raw-output '.SecurityGroups[] | .GroupId')
		echo "Region's Default SG ID: $sg"
		
		# Remove inbound rule
		aws ec2 revoke-security-group-ingress --profile $profile --region $region --group-id $sg --protocol all --cidr 0.0.0.0/0 --port all --source-group $sg
		# Remove outbound rule
		aws ec2 revoke-security-group-egress --profile $profile --region $region --group-id $sg --protocol all --cidr 0.0.0.0/0 --port all 
	fi	
done