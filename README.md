## Summary

Scripts to configure various elements of AWS.  I like the powershell cmdlet naming scheme, which I've followed for these scripts, which should hopefully be fairly self-explanatory.
 
## Background

We are using the Evident.io security platform, which has several signatures related to default AWS configurations, many of which are insecure out of the box.  Being able to quickly close default security holes in an automated fashion is the end goal for these scripts.
 
### Requirements

AWS-CLI with configured profile

### How to use

1.  Copy example.sh file to `your_project_name.sh`
2.  Edit profile to match the name of your AWS CLI profile if you are using somethign other than default ie. `profile="my_aws_profile"`
3.  Run `./your_project_name.sh`

### Warning

These scripts have the possibility of causing network related outages, speicifcally related to VPC default NACLs and default Security Groups.  While these groups are insecure by default and should not be used as is, your setup may make use of them.  Please ensure that you have configured the `used_regions` variable as described below to avoid causing issues.

### Configuring private variables

I store private variables within the project folder in a vars/ folder, which is ignored by git.  Each project has a bash file with all the needed variables defined that is called by the outer project.sh script.  That file looks like this:
```
#!/bin/bash

# Set the canonical user ID that will own the logging bucket
s3_user_id="my_64_digit_canonical_id"

# Define S3 bucket owner display name
s3_owner_display_name="my_root_account_display_name"

# Define regions we use 
used_regions=(
    us-east-1
    us-west-1
)

# This will gather a list of all regions for you when it is sourced from the main file
all_regions=$(aws ec2 describe-regions --output text --profile $profile | cut -f3)
```
