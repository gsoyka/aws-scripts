#!/bin/bash

# Define aws cli profile to use
profile="venicegeo"

# Get the plaintext username for all users
all_users_name=$(aws iam list-users --profile $profile | jq --raw-output '.Users[] | .UserName')

for user in $all_users_name
do
	echo -e "\nChecking Active Keys for User: $user"
	keys=$(aws iam list-access-keys --profile venicegeo --user-name $user | jq --raw-output '.AccessKeyMetadata[] | select(.Status | contains("Active")) | .AccessKeyId')
	if [ -z $keys ]
	then
		echo "User $user has no active keys"
	else	
		for key in $keys
		do 
			echo "Checking Key $key"
			last_use=$(aws iam get-access-key-last-used --profile $profile --access-key-id $key | jq 'select(.AccessKeyLastUsed.LastUsedDate | . == null or fromdateiso8601 < (now-7776000)) | .AccessKeyLastUsed.LastUsedDate')
			if [ -z $last_use ]
			then
				echo "Key $key has been used within 90 days"
			else
				echo "Disabling key $key for inactivity; last used: $last_use"
				aws iam update-access-key --profile $profile --user-name $user --access-key-id $key --status Inactive
			fi		
		done
	fi		
done	