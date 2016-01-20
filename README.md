## Reportek Docker image for Apache HTTP server based on eeacms/apache:2.4s

### Supported tags and respective Dockerfile links

  - `:latest` (apache 2.4.x)

### Base docker image

 - [hub.docker.com](https://registry.hub.docker.com/u/eeacms/reportek-apache)


### Source code

  - [github.com](http://github.com/eea/eea.docker.reportek.apache)


### Installation

1. Install [Docker](https://www.docker.com/).

## Usage


### Run with Docker Compose

Here is a basic example of a `docker-compose.yml` file using the `eeacms/reportek-apache` docker image:

    apache:
      image: eeacms/reportek-apache
      volume:
      - ./conf.d/virtual-host.conf:/:/usr/local/apache2/conf/extra/vh-my-app.conf
      ports:
      - "80:80"
      links:
      - webapp

    webapp:
      image: razvan3895/nodeserver


### You can also provide the j2 template which will be used to generate the config file based on the provided env variables:

    apache:
      image: eeacms/reportek-apache
      volume:
      - conf.d/virtual-host.j2:/:/tmp/vh.j2
      ports:
      - "80:80"
      links:
      - webapp
      env_file:
      - apache.env

    webapp:
      image: razvan3895/nodeserver

### Run it with Docker

    $ docker run -it --rm -v conf.d/virtual-host.conf:/usr/local/apache2/conf/extra/vh-my-app.conf -p 80:80 eeacms/reportek-apache


### Run it with environment variable set in apache.env

* `APACHE_SERVER_ADMIN` Email address of the Web server administrator
* `APACHE_SERVER_NAME` Server name
* `APACHE_HTTP_PROXY_TIMEOUT` Proxy timeout for http
* `BALANCER_NAME` Balancer name e.g. `pound` this is the link name
* `BALANCER_PORT` Balancer port e.g. `8080`
* `APACHE_HTTPS_PROXY_TIMEOUT` Proxy timeout for https
* `APACHE_DATA_HOSTNAME` The hostname
* `APACHE_DATA_FQDN` The fully qualified domain name
* `TPL_URL` The URL for the vhost j2 template
* `TPL_USER` The User for the template url
* `TPL_PASS` The Password for the template url
* `CERT_USER` The User for the certificates (if not specified, the template user will be used)
* `CERT_PASS` The Password for the certificates (if not specified, the template password will be used)
* `APACHE_SSL_CERT_SRC` The URL for the CERT file
* `APACHE_SSL_KEY_SRC` The URL for the Cert KEY file
* `APACHE_SSL_CHAIN_SRC` The URL for the CHAIN file

### Reload configuration file for Apache

    $ docker exec <name-of-your-container> reload


### Extend it

Build a `Dockerfile` with something similar:

    FROM eeacms/reportek-apache
    ADD your-file.conf /usr/local/apache2/conf/extra/vh-my-app.conf


## Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.


## Funding

[European Environment Agency (EU)](http://eea.europa.eu)
