# rpi-icinga + nconf

[![GitHub Issues](https://img.shields.io/github/issues/edgd1er/rpi-icinga.svg)](https://github.com/edgd1er/rpi-icinga/issues) 
[![GitHub Stars](https://img.shields.io/github/stars/edgd1er/rpi-icinga.svg?label=github%20%E2%98%85)](https://github.com/edgd1er/rpi-icinga/) 

[![Docker Pulls](https://img.shields.io/docker/pulls/edgd1er/rpi-icinga-nconf.svg)](https://hub.docker.com/r/edgd1er/rpi-icinga-nconf/) [![License](https://img.shields.io/github/license/edgd1er/rpi-icinga.svg)](LICENSE)


Raspberry Pi-compatible [Icinga](https://icinga.com/docs/icinga1/latest/en/) + [nconf](https://github.com/Bonsaif/new-nconf/archive/nconf-v1.4.0-final2.tar.gz) Docker image. Includes [mSMTP](https://wiki.debian.org/msmtp) for Email notifications.

Based on acch/rpi-icinga docker.

Updated base image with latest version except for icinga and nconf (EOL)

## Informations

* multi-arch thanks to buildx ( arm, amd64 )
* based on latest debian:buster-slim (Dockerfile.all)
* apache 2.4
* [icinga 1.14.2](https://github.com/Icinga/icinga-core) / [Nconf 1.4](https://github.com/Bonsaif/new-nconf/releases)
Both are EOL and icinga 1.x is a read only repository. (no updates to expect ; ) 
* Automatic backup once a week of icinga and nconf db: ``/usr/share/icinga/import_db_backup.sh YYYYMMDD``
* Import icinga, nconf df from backup: ``/usr/share/icinga/backupConfs.sh`` 
* Import into nconf database from existing icinga folder with: ``/usr/share/icinga/import_existing_nconf_into_db.sh``


## Usage

```
 docker run --rm \
  -p 80:80 \
  -p 443:443
  -v $(pwd)/etc:/etc/icinga \
  -v cache:/var/cache/icinga \
  -v $(pwd)/log:/var/log/icinga \
  -e MYSQL_HOST=mysqlServerHostname
  -e MYSQL_USER=user
  -e MYSQL_PASSWORD=password
  -e MYSQL_DATABASE=database
  -e MYSQL_PORT=3306
  -e SMTP_HOST=smtp.domain.tld
  -e SMTP_FROM=useremail@domain.tld
  -e SMTP_USER=username
  -e SMTP_PWD=password
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
        - "8009:443"
     volumes:
      #- cache:/var/cache/icinga
      #- :/var/log/icinga
      - ${pwd}/etc/:/etc/icinga
     env_file:
       - envMysql
       - envMsmtp
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

### envMysql:

MYSQL_ROOT_HOST=%
MYSQL_ROOT_PASSWORD=changeItToo
MYSQL_HOST=nconf-mysql
MYSQL_DATABASE=nconfdb
MYSQL_USER=nconf_user
MYSQL_PASSWORD=changeIt
MYSQL_HOST_PORT=3306

### envMsmtp

SMTP_HOST="smtp.domain.tld"
SMTP_FROM="sender_email"
SMTP_USER="sender_login"
SMTP_PWD="sender_password"

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
# htpasswd -c /etc/htpasswd.users icingaadmin
```
or mount a local file.

### create database.

Nconf needs a database to operate. database credentials (login, pwd, db name) are set in envMysql. Start script create the schema if missing.

/!\ during the script execution, access to the database is define for nconf, the file  /var/ww/html/nconf/config/mysql.php is populated with envMysql values.

### URLS

icinga: ```https://ip:port/icinga/```

nconf: ```https://ip:port/nconf/```

## Copyright

Copyright 2020 edgd1er, released under the [MIT license](LICENSE)
