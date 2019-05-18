#!/bin/sh
region="ap-southeast-1"
profile="grayudu"
s3_bucket="gangaapp-secret-101189138796-$region"
encrypted=/tmp/data.enc
src="./"
kms_alias='gangaapp'
key_id=`aws --profile $profile --region $region kms list-aliases --output text --query "Aliases[?AliasName=='alias/$kms_alias'].TargetKeyId | [0]"`
aws --profile $profile --region $region kms encrypt \
    --key-id $key_id \
    --plaintext fileb://$src/config.py \
    --query CiphertextBlob \
    --output text \
    | base64 --decode \
    > $encrypted

aws --profile $profile --region $region s3api put-object \
    --bucket $s3_bucket \
    --key dbconfig \
    --acl private \
    --body $encrypted \
    --output text \
    --query 'None' \
    | egrep -v '^None$' || true

