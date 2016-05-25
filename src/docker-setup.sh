#!/bin/bash
# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/*
set -x

CONFIG_FILE='/usr/local/apache2/conf/extra/vh-my-app.conf'
SSL_CERTS_PATH='/usr/local/apache2/conf'
VH_TPL='/tmp/vh.j2'

function gen_conf {
  j2 "$VH_TPL" > $CONFIG_FILE
}

function handle_ssl_certs {
  if [ ! -z "$SSL_CERT" -o ! -z "$SSL_KEY" ]; then
    echo -e "$SSL_CERT" > "$SSL_CERTS_PATH/server.crt"
    echo -e "$SSL_KEY" > "$SSL_CERTS_PATH/server.key"
    if [ ! -z "$SSL_CHAIN" ]; then
      echo -e "$SSL_CHAIN" > "$SSL_CERTS_PATH/server-chain.crt"
      chown apache:apache "$SSL_CERTS_PATH/server-chain.crt"
    fi
  fi
  if [ ! -f "$SSL_CERTS_PATH/server.crt" -o \
       ! -f "$SSL_CERTS_PATH/server.key" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
            -keyout "$SSL_CERTS_PATH/server.key" \
            -out "$SSL_CERTS_PATH/server.crt" \
            -subj "/C=../ST=./L=./O=./OU=./CN=localhost"
  fi
  chown apache:apache "$SSL_CERTS_PATH/server.crt" \
                      "$SSL_CERTS_PATH/server.key"
}

if [ -f "$VH_TPL" ]; then
  gen_conf
fi

if [ -f /usr/local/apache2/conf/extra/vh-*.conf ]; then
  echo 'Using mounted config file'
else
  if [ ! -f "$VH_TPL" ] && [ ! -z "$HTTP_TEMPLATE" ]; then
    echo -e "$HTTP_TEMPLATE" > "$VH_TPL"
    gen_conf
  else
    echo '<VirtualHost *:80>' > $CONFIG_FILE
    echo "ServerAdmin $APACHE_SERVER_ADMIN" >> $CONFIG_FILE
    echo "ServerName $APACHE_SERVER_NAME" >> $CONFIG_FILE
    echo "ServerAlias $APACHE_ServerAlias" >> $CONFIG_FILE
    echo 'ErrorLog /var/log/apache.log' >> $CONFIG_FILE
    if [ ! -z "$RewriteRule" ]; then
      echo 'RewriteEngine On' >> $CONFIG_FILE
      if [ ! -z "$RewriteCond" ]; then
        echo "RewriteCond $RewriteCond" >> $CONFIG_FILE
      fi
      echo "RewriteRule $RewriteRule" >> $CONFIG_FILE
    fi
    echo '</VirtualHost>' >> $CONFIG_FILE
  fi
fi

handle_ssl_certs
