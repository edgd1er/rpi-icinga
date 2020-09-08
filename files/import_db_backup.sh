#!/usr/bin/env bash
#
# import existing nconf generated files into empty database
#

ARC_DIR=/var/archives/$1

ARC_FILE=${ARC_DIR}/nconfdb.sql.gz

[[ ! -f $ARC_FILE ]] && echo "Error, $ARC_FILE not found.exit" && exit 1

gzip -dc ${ARC_FILE} | mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -P$MYSQL_HOST_PORT -D $MYSQL_DATABASE