#!/bin/bash

function Create-DefaultKey {
	profile=$1

	for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
	do
	    echo -e "\nListing Keys in region:'$region'..."
	    keys=$(aws kms list-keys --region $region --profile $profile | jq --raw-output '.Keys[] | .KeyId')
		
		if [ -z $keys ]
		then
			# Create Key
			key_id=$(aws kms create-key --region $region --profile $profile --description default | jq --raw-output '.KeyMetadata.KeyId')
			aws kms create-alias --region $region --profile $profile --target-key-id $key_id --alias-name "alias/default"
			aws kms enable-key-rotation --region $region --profile $profile --key-id $key_id
			echo "Created key: $key_id"
		else
			echo -e "Found existing keys:\n $keys"
		fi	
	done
}