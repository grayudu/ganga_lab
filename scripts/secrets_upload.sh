#!/bin/sh

#Image upload to s3 bucket
img_src=""
repo_s3bucket=""

aws --profile <profile> s3 cp $img_src/sf.jpeg s3://$repo_s3bucket/
aws --profile <profile> s3api put-object-acl --bucket $repo_s3bucket --key sf.jpeg --acl public-read

# cert and key encryption and upload to secret bucket for nginx configuration
s3_bucket="gangaapp-secret-101189138796-us-west-2"
encrypted=/tmp/data.enc
src="/Users/grayudu/"
kms_alias='gangaapp'
key_id=`aws --profile grayudu kms list-aliases --output text --query "Aliases[?AliasName=='alias/$kms_alias'].TargetKeyId | [0]"`
for i in server.crt server.key
do
aws --profile grayudu kms encrypt \
    --key-id $key_id \
    --plaintext fileb://$src/$i \
    --query CiphertextBlob \
    --output text \
    | base64 --decode \
    > $encrypted

aws --profile grayudu s3api put-object \
    --bucket $s3_bucket \
    --key nginx_$i \
    --acl private \
    --body $encrypted \
    --output text \
    --query 'None' \
    | egrep -v '^None$' || true
done

