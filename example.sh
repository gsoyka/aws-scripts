#!/bin/bash

# Define aws cli profile to use
profile="default"

# Source Functions
for file in /Users/gsoyka/Projects/aws-scripts/functions/*
do echo "Sourcing $file" && source $file
done        

# Source variables
source /Users/gsoyka/Projects/aws-scripts/vars/$profile.sh

### Main ###

# Iterate over all regions
for region in ${all_regions[*]}
do  Enable-VpcFlowLogs $profile $region
done

# Iterate over all used regions
for region in ${used_regions[*]}
do  Create-S3LogBuckets $profile $region
done

# Iterate over all unusued regions
for region in $all_regions
do
    if [[ ${used_regions[*]} =~ $region ]]
    then
        echo -e "\n$region is in Used Regions; Ignoring"
    else
        Set-DefaultSGRules $profile $region
        Delete-DefaultNaclRule $profile $region
    fi
done

# Enable bucket logging for all buckets in account
Enable-S3BucketLogging $profile $s3_user_id $s3_owner_display_name

# Enable S3 Object versioning for all buckets
Enable-S3ObjectVersioning $profile

# Ensure that a customer manager encryption key exists in all regions
Create-DefaultKey $profile

# Disable access keys that have not been used in 90 days
Disable-InactiveAccessKeys $profile