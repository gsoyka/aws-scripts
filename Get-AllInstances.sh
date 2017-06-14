#!/bin/bash
profile="venicegeo-prod"

for region in `aws ec2 describe-regions --output text --profile $profile | cut -f3`
do
     echo -e "\nListing Instances in region:'$region'..."
     aws ec2 describe-instances --region $region --profile $profile | jq '.Reservations[] | ( .Instances[] | {state: .State.Name, name: .KeyName, type: .InstanceType, key: .KeyName})'
done