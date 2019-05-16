#override the port
default["sslproxy-nginx"]["upstream"]["port"] = 8080

# default is for port 8080
default["sslproxy-nginx"]["upstreams"]["upstream#{node["sslproxy-nginx"]["upstream"]["port"]}"] = [
  "server 127.0.0.1:#{node["sslproxy-nginx"]["upstream"]["port"]};", # reference the port (it could be overwritten)
  "keepalive 32;"
]

default["sslproxy-nginx"]["root_location"] = [
  'proxy_set_header X-Forwarded-Host  $host;',
  'proxy_set_header X-Real-IP          $remote_addr;',
  'proxy_set_header X-Forwarded-Server $host;',
  'proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;',
  'proxy_http_version                  1.1;',
  'proxy_set_header Connection         "";',
  "proxy_pass                          http://upstream#{node["sslproxy-nginx"]["upstream"]["port"]};",
]

#default["sslproxy-nginx"]["pkgs"] =  { "nginx" => "1.8.0-1.el6.ngx" }
default["sslproxy-nginx"]["pkgs"] = 'nginx'

default["sslproxy-nginx"]["additional_locations"] = nil


default["sslproxy-nginx"]["worker_connections"] = 16384

default["sslproxy-nginx"]["region"] = node['ec2']['placement_availability_zone'].chop
