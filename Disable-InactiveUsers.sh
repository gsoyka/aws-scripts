#!/bin/bash

# Define aws cli profile to use
profile="venicegeo-prod"

# Get the arn of all users in the account
all_users_arn=$(aws iam list-users --profile $profile | jq --raw-output '.Users[] | .Arn')

# Get the plaintext username for all users
all_users_name=$(aws iam list-users --profile $profile | jq --raw-output '.Users[] | .UserName')

aws iam list-users --profile $profile | jq '.Users[] | select(.PasswordLastUsed | . == null or fromdateiso8601 < (now-7776000)) | {Username: .UserName, ID: .Arn, PasswordLastUsed: .PasswordLastUsed}'

for user in $all_users_name
do
	device=$(aws iam list-mfa-devices --profile $profile --user-name $user | jq '.MFADevices[]')
	if [ -z "$device" ]
	then
		echo "$user has no MFA device"
		aws iam list-user-policies --profile $profile --user-name $user
		#aws iam delete-user --profile $profile --user-name $user 
	fi	
	
done	