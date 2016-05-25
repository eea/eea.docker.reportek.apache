#!/bin/bash
# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/*
set -x

CONFIG_FILE='/usr/local/apache2/conf/extra/vh-my-app.conf'
if [ -z $SSL_CERTS_ROOT ]; then
  SSL_CERTS_ROOT='/usr/local/apache2/conf'
fi
VH_TPL='/tmp/vh.j2'

function gen_conf {
  exec env SSL_CERTS_ROOT=$SSL_CERTS_ROOT j2 "$VH_TPL" > $CONFIG_FILE
}

function handle_ssl_certs {
  if [ ! -z "$SSL_CERT" -o ! -z "$SSL_KEY" ]; then
    echo -e "$SSL_CERT" > "$SSL_CERTS_ROOT/server.crt"
    echo -e "$SSL_KEY" > "$SSL_CERTS_ROOT/server.key"
    if [ ! -z "$SSL_CHAIN" ]; then
      echo -e "$SSL_CHAIN" > "$SSL_CERTS_ROOT/server-chain.crt"
      chown apache:apache "$SSL_CERTS_ROOT/server-chain.crt"
    fi
  fi
  if [ ! -f "$SSL_CERTS_ROOT/server.crt" -o \
       ! -f "$SSL_CERTS_ROOT/server.key" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
            -keyout "$SSL_CERTS_ROOT/server.key" \
            -out "$SSL_CERTS_ROOT/server.crt" \
            -subj "/C=../ST=./L=./O=./OU=./CN=localhost"
  fi
  chown apache:apache "$SSL_CERTS_ROOT/server.crt" \
                      "$SSL_CERTS_ROOT/server.key"
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
  elif [ ! -z $TPL_URL ]; then
    curl -o "$VH_TPL" -u "$TPL_USER:$TPL_PASS" -k "$TPL_URL"

    if [ ! -z $APACHE_SSL_CERT_SRC ]; then
      if [ -n $CERT_USER ]; then
          CERT_USER=$TPL_USER
          CERT_PASS=$TPL_PASS
      fi
      curl -o "$SSL_CERTS_ROOT/server.crt" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_CERT_SRC
      curl -o "$SSL_CERTS_ROOT/server.key" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_KEY_SRC
      curl -o "$SSL_CERTS_ROOT/server-chain.crt" -u "$CERT_USER:$CERT_PASS" -k $APACHE_SSL_CHAIN_SRC
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

handle_ssl_certs
