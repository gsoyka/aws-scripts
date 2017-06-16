#!/bin/bash

# Define the aws cli profile to use
profile="venicegeo"

# Define desired name of log group
log_group_name="VPC-Flow-Logs"

# Define desired CloudWatch IAM role name
role_name="FlowLogsRole"

# Get ARN of IAM permission role
arn=$(aws iam --profile $profile list-roles | jq --raw-output --arg ROLE_NAME "$role_name" '.Roles[] | select(.RoleName | contains($ROLE_NAME)) | .Arn')

if [ -z $arn ]
then
	echo "Role $role_name does not exist, creating"
	#arn=$(aws iam create-role --profile $profile --role-name $role_name --assume-role-policy-document file://FlowLogsRole-Policy.json | jq '.Role[] | .Arn')
else
	echo "Found Existing ARN: $arn"		
fi	

#regions=("ap-southeast-1")
#for region in $regions
for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
do
	echo -e "\nConfiguring Region:'$region'..."
		
	# Check if our log group exists
	group_name=$(aws logs describe-log-groups --profile $profile --region $region | jq --arg GROUP_NAME "$log_group_name" '.logGroups[] | select(.logGroupName | contains($GROUP_NAME)) | .logGroupName')
	
	# If the log group does not exist, create it
	if [ -z $group_name ]
	then
		aws logs create-log-group --profile $profile --region $region --log-group-name $log_group_name
	else
		echo "Found Existing Log Group: $group_name"
	fi
	
	# Get IDs for all VPCs in the region
    vpcs=$(aws ec2 describe-vpcs --region $region --profile $profile | jq --raw-output '.Vpcs[] |  .VpcId')
	
	for vpc in $vpcs
	do
		echo -e "\nChecking flow logs on VPC: $vpc"
		# Check if Flow Log already exists
		log_id=$(aws ec2 describe-flow-logs --profile $profile --region $region --filter Name=resource-id,Values=$vpc Name=log-group-name,Values=VPC-Flow-Logs | jq --raw-output '.FlowLogs[] | .FlowLogId')
		
		if [ -z $log_id ]
		then
			# Enable flow logs
			echo "Added flow log: $(aws ec2 create-flow-logs --profile $profile --region $region --resource-ids $vpc --resource-type VPC --traffic-type ALL --log-group-name $log_group_name --deliver-logs-permission-arn $arn | jq --raw-output '.FlowLogIds[]')"
		else
			echo "Flow log $log_id already enabled"
		fi		
	done
done