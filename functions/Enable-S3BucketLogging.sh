#!/bin/bash

# This function enables logging for all S3 buckets in an account
function Enable-S3BucketLogging {
	profile=$1
	user_id=$2
	display_name=$3

	# Get a list of all buckets
	buckets=$(aws s3api list-buckets --profile $profile | jq --raw-output '.Buckets[] | .Name')

	for bucket in $buckets
	do
		# Check Object Versioning status
		log_bucket=$(aws s3api get-bucket-logging --profile $profile --bucket $bucket | jq '.LoggingEnabled.TargetBucket')
		
		# By default, versioning is disabled, and the command returns a null value
		if [ -z $log_bucket ]
		then
			echo "Object logging not enabled for bucket $bucket; Enabling"
			
			region=$(aws s3api get-bucket-location --profile $profile --bucket $bucket | jq --raw-output .LocationConstraint)
			
			# Account for aws cli returning null if bucket is in us-east-1 region
			if [ $region == null ]
			then
				region="us-east-1"
			fi	
			
			target_bucket="$profile-s3-logs-$region"
			
			# Add slash to bucket name for prefix, avoids issues with concatenation in jq
			bucket_prefix="$bucket/"

			# Define the logging policy via JSON to use
			json_config=$(jq -n --arg target_prefix "$bucket_prefix" --arg target_bucket "$target_bucket" --arg user_id "$user_id" --arg display_name "$display_name" '
			{
				"LoggingEnabled": {
					"TargetBucket": $target_bucket,
					"TargetPrefix": $target_prefix,
					"TargetGrants": [
						{
							"Grantee": {
								"Type": "CanonicalUser",
								"DisplayName": $display_name,
								"ID": $user_id
							},
							"Permission": "FULL_CONTROL"
						}			
					]
				}
			}'
			)
			
			# Write generated JSON configuration to a file
			echo $json_config > s3_logsettings.json
			
			# Adjust bucket ACL to allow logging group access
			#aws s3api put-bucket-acl \
			#  --profile $profile \
			#  --bucket $bucket \
			#  --grant-write URI=http://acs.amazonaws.com/groups/s3/LogDelivery \
			#  --grant-read-acp URI=http://acs.amazonaws.com/groups/s3/LogDelivery

			# Configure bucket logging 
			aws s3api put-bucket-logging \
			  --profile $profile \
			  --bucket $bucket \
			  --bucket-logging-status file://s3_logsettings.json
			
			# Clean up JSON File
			rm s3_logsettings.json

		else
			echo "Bucket: $bucket is logging to: $log_bucket"	
		fi
	done
}	
