#!/bin/bash
# This script deploys the CloudFormation stack set for Palisade.

# Get user inputs
read -p "Enter AWS Account ID : " AWS_ACCOUNT_ID
read -p "Enter Amazon Email ID : " AMAZON_EMAIL_ID
read -p "Enter Phone Number with country code: " PHONE_NUMBER
read -p "Enter Region list separated by space other than us-east-1: " REGION_LIST
read -p "By default, scans are performed in an interval of 15 mins (recommended), do you want to change this [yes/no]: " CHANGE_FREQUENCY
if [ "$CHANGE_FREQUENCY" == "yes" ]; then
    read -p "Enter new interval in minutes : " FREQUENCY_MINUTES
fi
FREQUENCY_MINUTES="${FREQUENCY_MINUTES:-15}"

# verify phone number
aws sns create-sms-sandbox-phone-number --phone-number $PHONE_NUMBER
read -p "Enter OTP received on your phone : " OTP
aws sns verify-sms-sandbox-phone-number --phone-number $PHONE_NUMBER --one-time-password $OTP

# Deploy stack set
aws cloudformation deploy --template AWSCloudFormationStackSetAdministrationRole.yml  --stack-name CloudformationStackSetAdministratorRole --region us-east-1 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --template AWSCloudFormationStackSetExecutionRole.yml --stack-name CloudformationStackSetExecutionRole --region us-east-1 --capabilities CAPABILITY_NAMED_IAM --parameter-overrides AdministratorAccountId=$AWS_ACCOUNT_ID
aws cloudformation create-stack-set --stack-set-name palisade-check --template-body file://template.yaml --region us-east-1 --parameters ParameterKey=AmazonEmailID,ParameterValue=$AMAZON_EMAIL_ID ParameterKey=EnablePhoneNotification,ParameterValue=yes ParameterKey=PhoneNumber,ParameterValue=$PHONE_NUMBER ParameterKey=NotificationFrequency,ParameterValue=$FREQUENCY_MINUTES --capabilities CAPABILITY_NAMED_IAM

aws cloudformation create-stack-instances --stack-set-name palisade-check --accounts $AWS_ACCOUNT_ID --regions us-east-1 $REGION_LIST







