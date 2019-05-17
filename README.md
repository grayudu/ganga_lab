# ganga_lab
deploying 3tier application

# AWS 3tier app demo


## Details

* demo application hosted on default VPC of aws and subnets.
* deveoped using terraforms, chef-solo
* AWS KMS used for pushing secrets to cloud.

## Step 1 - Creating S3 buckets, RDS, KMS
- Update variables ./otc/variables.tf except for db password
- Run terraform cmds for creating KMS, S3 Buckets and RDS
- terraform plan & apply prompt for db password.
```
cd terraform/otc
terraform init
terraform plan
terraform apply #say yes when all resources listing correctly
```
## Step 2 DB config and secrets upload to s3 secret bucket
- create self signed cert and key
```
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out server.crt -keyout server.key
```
- update all attributes with otc terraform outputs details #config.py.
- update script with kms alias and bucket details #secrets_upload.sh
- encrypt file (get kms id from otc terraform outputs)
```
- execute ./secrets_upload.sh
```

## Step 3 Upload Chef cookbooks and image file to s3
```
- aws --profile <profile> s3 cp <path>/sf.jpeg s3://<s3bucket>/
- aws --profile <profile> s3api put-object-acl --bucket <s3bucket> --key sf.jpeg --acl public-read
```
upload chef
```
cd chef
- update attributes for s3 bucket details
zip -r chef-0.1.0.zip * #get all cookbooks, recipes, roles and environments.
aws --profile grayudu s3 cp chef-0.1.0.zip s3://<s3bucket>/
```
## Step 4 execute demo app
- Creating ALB listener on 443, so ssl certificate has to be upload to IAM
- Encrypt cert and key using aws KMS
```
aws --profile <profile> kms encrypt --key-id <keyid> --plaintext fileb:///<path>/server.crt --output text --query CiphertextBlob > /tmp/server.crt
aws --profile <profile> kms encrypt --key-id <keyid> --plaintext fileb:///<path>/server.key --output text --query CiphertextBlob > /tmp/server.key

```
update path of encrypted ssl cert and key on ./demo/main.tf and also update bucketname in variables.tf

```hcl
cd terraform/demo
terraform init
terraform plan
terraform apply #say yes when all resources listing correctly
```
- please update with aws profile details in terraform provider section.
