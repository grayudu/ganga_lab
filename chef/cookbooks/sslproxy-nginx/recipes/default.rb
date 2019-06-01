#
# Cookbook Name:: sslproxy-nginx
# Recipe:: default
#
#
# All rights reserved - Do Not Redistribute
#


# install packages
#node["sslproxy-nginx"]["pkgs"].each do |_pkg, _ver|
  yum_package node["sslproxy-nginx"]["pkgs"] do
    action :install
#    version _ver
    retries 5
  end
#end

# create dir
directory "/etc/ssl/" do
  action :create
  owner "nginx"
  group "nginx"
  mode "750"
end

# enable nginx
service "nginx" do
  service_name "nginx"
  enabled true
  running true
  supports :status => true, :restart => true, :reload => true, :start => true, :stop => true
  action [ :enable ]  
end


bash "install-ssl-certs" do
   user "root"
   cwd "/dev/shm/"
   code <<-EOS
aws s3api get-object --bucket #{node['ganga-app']["secret_bucket"]} --key nginx_#{node["sslproxy-nginx"]["ssl"]["name"]}.key #{node["sslproxy-nginx"]["ssl"]["name"]}.key
aws kms decrypt --region #{node["sslproxy-nginx"]["region"]} --ciphertext-blob fileb://#{node["sslproxy-nginx"]["ssl"]["name"]}.key --output text --query Plaintext | base64 --decode > #{node["sslproxy-nginx"]["ssl"]["name"]}_key
aws s3api get-object --bucket #{node['ganga-app']["secret_bucket"]} --key nginx_#{node["sslproxy-nginx"]["ssl"]["name"]}.crt #{node["sslproxy-nginx"]["ssl"]["name"]}.crt
aws kms decrypt --region #{node["sslproxy-nginx"]["region"]} --ciphertext-blob fileb://#{node["sslproxy-nginx"]["ssl"]["name"]}.crt --output text --query Plaintext | base64 --decode > #{node["sslproxy-nginx"]["ssl"]["name"]}_crt
cp #{node["sslproxy-nginx"]["ssl"]["name"]}_crt /etc/ssl/#{node["sslproxy-nginx"]["ssl"]["name"]}.cer
cp #{node["sslproxy-nginx"]["ssl"]["name"]}_key /etc/ssl/#{node["sslproxy-nginx"]["ssl"]["name"]}.key
EOS
end

#create Stronger DHE Parameters

#execute "DH creation" do
#	command "cd /etc/ssl/certs && openssl dhparam -out dhparam.pem 2048"
#end


# if main conf changes, restart nginx
template "/etc/nginx/nginx.conf" do
  source "main-nginx.conf.erb"
  owner "root"
  group "root"
  mode '0444'
  notifies :restart, resources(:service => "nginx")
end

# if conf changes, restart nginx
template "/etc/nginx/conf.d/default.conf" do
  source "default.conf.erb"
  owner "root"
  group "root"
  mode '0444'
  notifies :restart, resources(:service => "nginx")
end

# log rotate
cookbook_file "/etc/logrotate.d/nginx" do
    source "nginx.logrotate"
    mode "0644"
    owner "root"
    group "root"
end

# increasing the limits
cookbook_file "/etc/security/limits.d/nginx.conf" do
    source "nginx-limits.conf"
    mode "0644"
    owner "root"
    group "root"
    notifies :restart, resources(:service => "nginx")    
end

cookbook_file "/etc/nginx/conf.d/stub_status.conf" do
    source "stub_status.conf"
    mode "0644"
    owner "root"
    group "root"
    notifies :restart, resources(:service => "nginx")
end

cookbook_file "/dev/shm/install.sh" do
    source "install.sh"
    mode "0644"
    owner "root"
    group "root"
    notifies :restart, resources(:service => "nginx")
end

execute "install amplify" do
       command "cd /dev/shm && sh install.sh"
end

service "nginx" do
  service_name "nginx"
  action [ :start ]
end
