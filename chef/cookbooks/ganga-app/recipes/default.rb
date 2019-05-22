
# Cookbook Name:: ganga-app
# Recipe:: default
#
# Copyright 2019
#
# All rights reserved - Do Not Redistribute
#

group "app" do
  action :create
  gid 603
end


user 'app' do
  gid 'app'
  shell '/bin/bash'
  home '/home/app'
  system true
  action :create
end

%w[ /var/log/ganga_app /etc/app /etc/app/templates ].each do |path|
  directory path do
    action :create
    owner "app"
    group "app"
    mode "750"
  end
end


bash "install-app" do
  user "root"
  cwd "/dev/shm/"
  ignore_failure true
  code <<-EOS
  pip install flask
  pip install boto3
  pip install pymysql
EOS
end

bash "DBConfig" do
   user "root"
   cwd "/dev/shm/"
   code <<-EOS
aws s3api get-object --bucket #{node['ganga-app']["secret_bucket"]} --key dbconfig  dbconfig.py
aws kms decrypt --region #{node["sslproxy-nginx"]["region"]} --ciphertext-blob fileb://dbconfig.py --output text --query Plaintext | base64 --decode > config.py
cp config.py /etc/app/
chmod 755 /etc/app/config.py
EOS
end

template "/etc/app/app.py" do
  source "app.py.erb"
  owner "app"
  group "app"
  mode '0755'
end

template "/etc/app/templates/home.html" do
  source "home.html.erb"
  owner "app"
  group "app"
  mode '0755'
end

cookbook_file "/etc/app/templates/health.html" do
    source "health.html"
    mode "0644"
    owner "app"
    group "app"
end

cookbook_file "/etc/app/templates/diag.html" do
    source "diag.html"
    mode "0644"
    owner "app"
    group "app"
end

cookbook_file "/etc/app/templates/stats.html" do
    source "stats.html"
    mode "0644"
    owner "app"
    group "app"
end

cookbook_file "/etc/init.d/ganga_app" do
    source "ganga_app"
    mode "0755"
    owner "app"
    group "app"
end

directory "/home/app" do
  action :create
  owner "app"
  group "app"
  mode "750"
end


# enable nginx
service "ganga_app" do
  service_name "ganga_app"
  enabled true
  running true
  supports :status => true, :restart => true, :reload => true, :start => true, :stop => true
  action [ :enable ]
end

service "ganga_app" do
 service_name "ganga_app"
 action [ :start ]
end


