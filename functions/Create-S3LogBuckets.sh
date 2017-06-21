#!/bin/bash

function Create-S3LogBuckets {
	profile=$1
	bucket_region=$2
	bucket="$profile-s3-logs-$bucket_region"

	# Check if our bucket exists and create if needed
	status=$(aws s3api head-bucket --profile $profile --bucket $bucket 2>/dev/null )
	if [[ $? != 0 ]]
	then
		echo "Bucket does not exist yet"
		if [ $bucket_region == "us-east-1" ]
		then
			# For US-East-1 region, call the create command without the location constraint
			aws s3api create-bucket --profile $profile --bucket $bucket --acl private
		else
			# For all other regions, constrain the bucket to our region
			aws s3api create-bucket --profile $profile --bucket $bucket --acl private --create-bucket-configuration LocationConstraint="$bucket_region"
		fi
		sleep 2	 
	fi
		
	# Adjust bucket ACL to allow logging group access
	aws s3api put-bucket-acl \
	  --profile $profile \
	  --bucket $bucket \
	  --grant-write URI=http://acs.amazonaws.com/groups/s3/LogDelivery \
	  --grant-read-acp URI=http://acs.amazonaws.com/groups/s3/LogDelivery
	
	# Enable bucket object versioning
	aws s3api put-bucket-versioning --profile $profile --bucket $bucket --versioning-configuration Status=Enabled
	
	# Define the lifecycle policy via JSON to use
	json_config=$(jq -n '
	{
		"Rules": [
			{
				"Expiration": {
					"Days": 7
				},
				"ID": "7 Day Expire",
				"Filter": {
					"Prefix": ""
				},
				"Status": "Enabled",
				"NoncurrentVersionExpiration": {
					"NoncurrentDays": 14
				}
			}
		]
	}'
	)
	
	# Write generated JSON configuration to a file
	echo $json_config > s3_lifecyclepolicy.json
	
	# Configure bucket lifecycle
	aws s3api put-bucket-lifecycle-configuration \
	  --profile $profile \
	  --bucket $bucket \
	  --lifecycle-configuration file://s3_lifecyclepolicy.json
	
	# Clean up JSON File
	rm s3_lifecyclepolicy.json
	
	echo -e "Configured bucket: $bucket"
}
