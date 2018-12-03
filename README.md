# rpi-icinga + nconf

[![GitHub Issues](https://img.shields.io/github/issues/acch/rpi-icinga.svg)](https://github.com/edgd1er/rpi-icinga/issues) [![GitHub Stars](https://img.shields.io/github/stars/edgd1er/rpi-icinga.svg?label=github%20%E2%98%85)](https://github.com/edgd1er/rpi-icinga/) [![Docker Pulls](https://img.shields.io/docker/pulls/edgd1er/rpi-icinga.svg)](https://hub.docker.com/r/edgd1er/rpi-icinga/) [![License](https://img.shields.io/github/license/edgd1er/rpi-icinga.svg)](LICENSE)

Raspberry Pi-compatible [Icinga](http://docs.icinga.com/latest/en/) + [nconf](https://github.com/Bonsaif/new-nconf/archive/nconf-v1.4.0-final2.tar.gz) Docker image. Includes [SSMTP](https://linux.die.net/man/8/ssmtp) for Email notifications.

Based on acch/rpi-icinga docker.

## Usage


#
```
 docker run --rm \
  -p 80:80 \
  -v $(pwd)/etc:/etc/icinga \
  -v cache:/var/cache/icinga \
  -v $(pwd)/log:/var/log/icinga \
  edgd1er/rpi-icinga-nconf
```


Run with docker-compose:

```
# docker-compose.yml
version: '3.1'
services:
    icinga:
     image: edgd1er/rpi-icinga-nconf:latest
     restart: unless-stopped
     ports:
        - "8008:80"
     volumes:
      #- cache:/var/cache/icinga
      #- :/var/log/icinga
      - ${pwd}/etc/:/etc/icinga
     env_file:
       - envMysql
     tmpfs:
        - /var/log/icinga
        - /var/cache/icinga
     depends_on:
        - nconf-mysql
    nconf-mysql:
      env_file:
      - envMysql
      image: mysql:5.7
      restart: unless-stopped
      expose:
      - "3306"
```

## Volumes

This image exposes the following volumes:

```
/etc/icinga                   Icinga configuration files
/var/cache/icinga             Icinga state retention and cache files
/var/log/icinga               Icinga log files
```

This compose-file used as example set hereunder volumes in ram, that are lost when container is stopped

```
/var/cache/icinga             Icinga state retention and cache files
/var/log/icinga               Icinga log files
```


## Installation

### htpassd
Icinga does not set any default password for the admin user. Run the following command to define a password for the admin user:

```
# htpasswd -c etc/htpasswd.users icingaadmin
```

### create database.

Nconf needs a database to operate. database credentials (login, pwd, db name) are set in envMysql. 

execute at first container's run
```
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE -e /usr/share/icinga/create_database.sql 
```

## Copyright

Copyright 2017 Achim Christ, released under the [MIT license](LICENSE)
