#override the port

default["ganga-app"]["port"] = 8080

default["ganga-app"]["region"] = node['ec2']['placement_availability_zone'].chop

default["ganga-app"]["Project"] = "gangademo"
default['ganga-app']["secret_bucket"] = "gangaapp-secret-101189138796-us-west-2"
default["ganga-app"]["s3_endpoint"] = "https://s3-us-west-2.amazonaws.com/gangaapp-101189138796-us-west-2/sf.jpeg"

