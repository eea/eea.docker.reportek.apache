#!/bin/bash
# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/*
set -x
CONFIG_FILE='/usr/local/apache2/conf/extra/vh-my-app.conf'
SSL_CERTS_PATH='/etc/pki/tls'

mkdir -p $SSL_CERTS_PATH/certs
mkdir -p $SSL_CERTS_PATH/private

VH_TPL='/tmp/vh.j2'
function gen_conf {
  j2 "$VH_TPL" > $CONFIG_FILE
}

if [ -f "$VH_TPL" ]; then
  gen_conf
fi

if [ -f /usr/local/apache2/conf/extra/vh-*.conf ]; then
  echo 'Using mounted config file'
else
  if [ ! -z $TPL_URL ]; then
    curl -o "$VH_TPL" -u "$TPL_USER:$TPL_PASS" -k "$TPL_URL"

    if [ ! -z $APACHE_SSL_CERT_SRC ]; then
      if [ -n $CERT_USER ]; then
          CERT_USER=$TPL_USER
          CERT_PASS=$TPL_PASS
      fi
      curl -o "$SSL_CERTS_PATH/certs/server.crt" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_CERT_SRC
      curl -o "$SSL_CERTS_PATH/private/server.key" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_KEY_SRC
      curl -o "$SSL_CERTS_PATH/certs/server-chain.crt" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_CHAIN_SRC
    fi
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

if [ ! -f /usr/local/apache2/conf/server.crt -o \
     ! -f /usr/local/apache2/conf/server.key ]; then
  openssl req -x509 -nodes -newkey rsa:2048 \
          -keyout /usr/local/apache2/conf/server.key \
          -out /usr/local/apache2/conf/server.crt \
          -subj "/C=../ST=./L=./O=./OU=./CN=localhost"
  chown apache:apache /usr/local/apache2/conf/server.crt \
                      /usr/local/apache2/conf/server.key
fi
