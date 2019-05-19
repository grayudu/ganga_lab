#override the port

default["ganga-app"]["port"] = 8080

default["ganga-app"]["region"] = node['ec2']['placement_availability_zone'].chop

default["ganga-app"]["Project"] = "gangaapp"
default['ganga-app']["secret_bucket"] = "#{node["ganga-app"]["Project"]}-secret-#{node["ec2"]["account_id"]}-#{node["ganga-app"]["region"]}"
default["ganga-app"]["s3_endpoint"] = "https://#{node["ganga-app"]["Project"]}-#{node["ec2"]["account_id"]}-#{node["ganga-app"]["region"]}.s3.#{node["ganga-app"]["region"]}.amazonaws.com/sf.jpeg"
