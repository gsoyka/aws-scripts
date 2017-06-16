#!/bin/bash

# Define regions we want to exclude
used_regions=(
	us-east-1
	us-west-1
	us-west-2 
)

# Define aws cli profile to use
profile="venicegeo"

# Parameter 1 is the Region
function deleteAllowEgressRules()
{
	rules=$(aws ec2 describe-network-acls --profile $profile --region $1 --filters "Name=default,Values=true" | jq --raw-output '.NetworkAcls[] | .Entries[] | select(.Egress == true ) | select(.RuleAction | contains("allow")) | .RuleNumber')
	if [ -z "$rules" ]
		then 
			echo "No Allow Egress Rules Found"
		else	
			for rule in $rules
			do
				aws ec2 delete-network-acl-entry --profile $profile --region $region --network-acl-id $nacl  --rule-number 100 --egress
				echo "Removed Egress rule: $rule"
			done
		fi
}

# Parameter 1 is the region
function deleteAllowIngressRules()
{
	rules=$(aws ec2 describe-network-acls --profile $profile --region $1 --filters "Name=default,Values=true" | jq --raw-output '.NetworkAcls[] | .Entries[] | select(.Egress == false ) | select(.RuleAction | contains("allow")) | .RuleNumber')
	if [ -z "$rules" ]
	then 
		echo "No Allow Ingress Rules Found"
	else	
		for rule in $rules
		do
			aws ec2 delete-network-acl-entry --profile $profile --region $region --network-acl-id $nacl  --rule-number 100 --ingress
			echo "Removed Ingress rule: $rule"
		done
	fi	
}

# Loop over all EC2 regions
for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
do
	if [[ ${used_regions[*]} =~ $region ]]
	then
		echo -e "\n$region is in Used Regions; Ignoring"
	else
		echo -e "\n$region is not in Used Regions"
		
		# Get Default NACL for region
		nacl=$(aws ec2 describe-network-acls --profile $profile --region $region --filters Name="default",Values="true" | jq --raw-output '.NetworkAcls[] | .NetworkAclId')
		echo "Region's Default nacl: $nacl"
		
		# Delete the ingress rule
		deleteAllowIngressRules $region 
		
		# Delete the egress rule
		deleteAllowEgressRules $region 
		
		# List current ACLs to verify deletion
		aws ec2 describe-network-acls --profile $profile --region $region --filters --network-acl-ids $nacl  | jq '.NetworkAcls[] | .Entries[] | {rule: .RuleNumber, cidr: .CidrBlock, rule_action: .RuleAction, egress: .Egress}'
	fi	

done