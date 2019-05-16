sslproxy-nginx Cookbook
======================
Creates an NGINX server that does uptream to a another process after doing the SSL Termination.

By default this will configure an upstream server based on the port mentioned `['upstream']['port']`
and configures to `location /` to point to that upstream.
