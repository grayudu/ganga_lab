# Generic solo.rb
file_cache_path  "/var/chef/"
cookbook_path  "/var/chef/cookbooks"
environment_path "/var/chef/environments"
role_path "/var/chef/roles"
data_bag_path  "/var/chef/data_bags"
`mkdir -p /var/log/chef`
log_location "/var/log/chef/chef.log"
