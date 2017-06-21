#!/bin/bash

# Define aws cli profile to use
profile="venicegeo"

function size_buckets {
	
	# Set default search string to null (meaning search all buckets)
	search_base=${1:null}
	
	# Get a list of all buckets
	buckets=$(aws s3api list-buckets --profile $profile | jq --raw-output '.Buckets[] | .Name')

	for bucket in $buckets
	do
		if [[ "$bucket" == *"$search_base"* ]]
		then
			size=$(aws s3 ls --profile $profile --summarize --human-readable --recursive s3://$bucket | grep "Total Size")
			echo "Bucket: $bucket $size"
		fi	
	done
}

size_buckets "venicegeo-s3-logs"
