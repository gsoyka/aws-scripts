#!/bin/bash

function Enable-S3ObjectVersioning {
	# Define aws cli profile to use
	profile=$1

	# Get a list of all buckets
	buckets=$(aws s3api list-buckets --profile $profile | jq --raw-output '.Buckets[] | .Name')

	for bucket in $buckets
	do
		# Check Object Versioning status
		status=$(aws s3api get-bucket-versioning --profile $profile --bucket $bucket | jq --raw-output .Status)
		
		# By default, versioning is disabled, and the command returns a null value
		if [ -z $status ]
		then
			echo "Object versioning not enabled for bucket $bucket; Enabling"
			aws s3api put-bucket-versioning --profile $profile --bucket $bucket --versioning-configuration Status=Enabled
		else
			echo "Object versioning has status: $status for bucket: $bucket"	
		fi
	done
}