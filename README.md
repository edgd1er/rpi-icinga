# rpi-icinga + nconf

[![GitHub Issues](https://img.shields.io/github/issues/edgd1er/rpi-icinga.svg)](https://github.com/edgd1er/rpi-icinga/issues) 
[![GitHub Stars](https://img.shields.io/github/stars/edgd1er/rpi-icinga.svg?label=github%20%E2%98%85)](https://github.com/edgd1er/rpi-icinga/) 

[![Docker Pulls](https://img.shields.io/docker/pulls/edgd1er/rpi-icinga-nconf.svg)](https://hub.docker.com/r/edgd1er/rpi-icinga-nconf/) [![License](https://img.shields.io/github/license/edgd1er/rpi-icinga.svg)](LICENSE)

![](https://badgen.net/docker/size/edgd1er/nut-stats/latest/amd64?icon=docker&label=Size%20amd64)
![](https://badgen.net/docker/size/edgd1er/nut-stats/latest/arm/v7?icon=docker&label=Size%20armv7)
![](https://badgen.net/docker/size/edgd1er/nut-stats/latest/arm/v6?icon=docker&label=Size%20armv6)

![](https://badgen.net/docker/layers/edgd1er/nut-stats/latest/amd64?icon=docker&label=Layers%20amd64)
![](https://badgen.net/docker/layers/edgd1er/nut-stats/latest/arm/v7?icon=docker&label=Layers%20armv7)
![](https://badgen.net/docker/layers/edgd1er/nut-stats/latest/arm/v6?icon=docker&label=Layers%20armv6)

Raspberry Pi-compatible [Icinga](https://icinga.com/docs/icinga1/latest/en/) + [nconf](https://github.com/Bonsaif/new-nconf/archive/nconf-v1.4.0-final2.tar.gz) Docker image. Includes [mSMTP](https://wiki.debian.org/msmtp) for Email notifications.

Based on acch/rpi-icinga docker.

buster debian image is the last version available as icinga and nconf are EOL and no more available on bookworm.

## Informations

* multi-arch thanks to buildx ( armv7,arm64, amd64 ). arm/v6 image is no more available (2022).
* based on debian:buster-slim (Dockerfile.all)
* apache 2.4
* [icinga 1.14.2](https://github.com/Icinga/icinga-core) / [Nconf 1.4](https://github.com/Bonsaif/new-nconf/releases)
Both are EOL and icinga 1.x is a read only repository. (no updates to expect ;) ) 
* Automatic backup once a week of icinga and nconf db: ``/usr/share/icinga/backupConfs.sh`` 
* Import icinga, nconf df from backup: ``/usr/share/icinga/import_backup.sh YYYYMMDD`` 
* Import into nconf database from existing icinga folder with: ``/usr/share/icinga/import_existing_nconf_into_db.sh``
* define user and password access.
* every week clean icinga archives logs over MAXDAYS. rotation is on a daily basis.
* Enable/Disable external commands through env: EXTERNAL_COMMANDS_ENABLE
* Notifications: change miscommand: 
    * notify-host-by-email: /bin/mail -> /usr/bin/msmtp
    * notify-service-by-email: /bin/mail -> /usr/bin/msmtp
* Added non-free contrib repositories to allow snmp-mibs-downloader to update mibs definitions.
* alias plugins to list available plugins    
* added docs from archived github repository (build dockerfile.builddoc, tar docs, import docs)
* CMDS to allow commands.cfg in icinga.cfg (notify-service-by-email, notify-host-by-email, ...)

## Usage

```
 docker run --rm \
  -p 80:80 \
  -p 443:443
  -v cache:/var/cache/icinga \
  -v $(pwd)/log:/var/log/icinga \
  -e EXTERNAL_COMMANDS_ENABLE=0
  -e CMDS='N'
  -e REMOVE_OLDER_THAN=320 \
  -e MYSQL_HOST=mysqlServerHostname
  -e MYSQL_USER=user
  -e MYSQL_PASSWORD=password
  -e MYSQL_DATABASE=database
  -e MYSQL_PORT=3306
  -e SMTP_HOST=smtp.domain.tld
  -e SMTP_PORT=1234
  -e SMTP_FROM=useremail@domain.tld
  -e SMTP_USER=username
  -e SMTP_PWD=password
  edgd1er/rpi-icinga-nconf
```


Run with docker-compose:

```
# docker-compose.yml
version: '3.5'
services:
    icinga:
     image: edgd1er/rpi-icinga-nconf:latest
     restart: unless-stopped
     ports:
        - "8008:80"
        - "8009:443"
     environment:
      TZ: "Europe/Paris"
      CMDS: 'N'
      REMOVE_OLDER_THAN: "120"
      EXTERNAL_COMMANDS_ENABLE: "1"
      SMTP_HOST: "smtp.myisp.tld"
      SMTP_PORT: 1234
      SMTP_FROM: "send_adress@domain.tld"
      SMTP_USER: "recipient@doamin.tld"
      SMTP_PWD: "smtp_password"
      SMTP_STARTTLS: "on"
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

### envMysql:

MYSQL_ROOT_HOST=%
MYSQL_ROOT_PASSWORD=changeItToo
MYSQL_HOST=nconf-mysql
MYSQL_DATABASE=nconfdb
MYSQL_USER=nconf_user
MYSQL_PASSWORD=changeIt
MYSQL_HOST_PORT=3306

## Volumes

This image exposes the following volumes:

```
/var/cache/icinga             Icinga state retention and cache files
/var/log/icinga               Icinga log files
```

This compose-file used as example set hereunder volumes in ram, that are lost when container is stopped

```
/var/cache/icinga             Icinga state retention and cache files
/var/log/icinga               Icinga log files
```

`/etc/icinga/global` and `/etc/icinga/Default_collector/)` may be mounted to keep icinga's configuration between creations.

## Installation

### htpassd

At each restart, password is defined using HTUSER and HTPASS variables values.

or mount a local file as read only.

### create database.

Nconf needs a database to operate. database credentials (login, pwd, db name) are set in envMysql. Start script create the schema if missing.

/!\ during the script execution, access to the database is define for nconf, the file  /var/ww/html/nconf/config/mysql.php is populated with envMysql values.

### URLS

icinga: ```https://ip:port/icinga/```

nconf: ```https://ip:port/nconf/```

### Documentation

Documentation is generated using [icinga-doc](https://github.com/Icinga/icinga-doc/) project. As the project is archived, a doc archive is shipped with the docker context (included in the project).

### Notifications

[ssmtp](https://wiki.debian.org/sSMTP) is not maintained anymore.
As a result of the change to [msmtp](https://wiki.debian.org/msmtp), notifications command lines have to be rewritten. mail -s is not supported by msmtp.
The subject (-s "<value>") need to be removed and a "subject:<value>\n\n" is to be added in front of the message.

As per config, the default value is for the command: notify-host-by-email
```bash 
/usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /usr/bin/sendmail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$
```
the adapted command line would be:
```bash
/usr/bin/printf "%b" "subject:** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$\n\n ******* Nagios *****\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\nDate/Time: $LONGDATETIME$\n" | /usr/bin/msmtp $CONTACTEMAIL$
```

This can be performed through the web interface: miscommands => notify-host-by-email, notify-service-by-email
or with the script /usr/share/icinga/mail_to_smtp.sh

SQL query to fetch command lines for both notifications (host/service)
```SQL
select cv.fk_id_item, cv.attr_value, cv.fk_id_attr
from ConfigAttrs ca , ConfigValues cv
where ca.fk_id_class = 13 # misccommands
and cv.fk_id_attr = ca.id_attr
and cv.fk_id_attr =99 #command_line
and cv.fk_id_item in (select cv2.fk_id_item from ConfigValues cv2 where
cv2.attr_value like 'notify%')
order by cv.fk_id_item ;
``

## Copyright

Copyright 2020 edgd1er, released under the [MIT license](LICENSE)
