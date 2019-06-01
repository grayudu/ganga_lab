# ganga_lab
deploying 3tier application

# AWS 3tier app demo


## Details

* demo python application hosted on custom VPC with multi azs public and private subnets and NAT.
* Creating RDS (mysql) for persistent store.
* deveoped using terraforms, chef-solo as configuration management
* AWS KMS used for pushing secrets to cloud.
## Inputs
- Update variables ./otc/variables.tf except for db password

| Name | Value |
|------|-------------|
| region | us-east-1 |
| profile | aws profile | 
| azs | ["us-east-1a", "us-east-1b", "us-east-1c"]|

## Step 1 - Creating S3 buckets, RDS, KMS
- Run terraform cmds for creating KMS, S3 Buckets and RDS
- terraform plan & apply prompt for db password.
Executing selected resource as a pre-requisite for encrypted db password before creating RDS.
```
cd terraform/otc
terraform init
terraform plan -target=null_resource.enc_dbpasswd
terraform apply -target=null_resource.enc_dbpasswd
```
Rest of resource will be created in following execution
```
terraform plan
terraform apply #say yes when all resources listing correctly
```
SSL certgenerated using openssl. sample available under scripts dir.
```
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out server.crt -keyout server.key
```
## Step 2 DB config  to s3 secret bucket
- update all attributes with otc terraform outputs details #config.py.
- update script with kms alias and bucket details #secrets_upload.sh
- encrypt file (get kms id from otc terraform outputs)
```
- execute ./secrets_upload.sh
```

## Step 3 execute demo app

## Inputs
- Update variables ./demo/variables.tf

| Name | Value |
|------|-------------|
| region | us-east-1 |
| profile | aws profile | 
| key_name | key_pair name|

```
cd terraform/demo
terraform init
terraform plan
terraform apply #say yes when all resources listing correctly
```
