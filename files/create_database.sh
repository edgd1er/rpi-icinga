#!/usr/bin/env bash
#
# create tables ofr nconf to operate
#

mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE  < /usr/share/icinga/create_database.sql