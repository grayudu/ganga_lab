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
Executing selected resource as a pre-requisite for encrypted db password before creating RDS.
```
terraform init
terraform plan
terraform apply -target=null_resource.enc_dbpasswd
```
Rest of resource will be created in following execution
```
cd terraform/otc
terraform plan
terraform apply #say yes when all resources listing correctly
```
SSL certgenerated using openssl. sample available under scripts dir.
```
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out server.crt -keyout server.key
```
## Step 2 DB config  to s3 secret bucket
- create self signed cert and key
- update all attributes with otc terraform outputs details #config.py.
- update script with kms alias and bucket details #secrets_upload.sh
- encrypt file (get kms id from otc terraform outputs)
```
- execute ./secrets_upload.sh
```

## Step 3 Upload Chef cookbooks
upload chef
```
cd chef
- update attributes for s3 bucket details
zip -r chef-0.1.0.zip * #get all cookbooks, recipes, roles and environments.
aws --profile grayudu s3 cp chef-0.1.0.zip s3://<s3bucket>/
```
## Step 4 execute demo app
Update variable with regard s3 bucket and profile
```
cd terraform/demo
terraform init
terraform plan
terraform apply #say yes when all resources listing correctly
```
- please update with aws profile details in terraform provider section.
