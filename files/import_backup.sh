#!/usr/bin/env bash
#
# import existing nconf generated files into empty database
#
set -e

[[ $# -eq 0 ]] && echo -e "\n/!\ Missing arg, YYYY-MM-DD is needed.\n" && exit || echo

ARC_DIR=/var/archives/$1
[[ ! -d ${ARC_DIR} ]] && echo -e "\n/!\ Error, $ARC_DIR not found.exit" && exit 1 || echo

ARC_DUMP=${ARC_DIR}/nconfdb.sql.gz
ARC_FILE=${ARC_DIR}/icinga.tar.gz

if [[ ! -f ${ARC_DUMP} ]]; then
  echo -e "\n/!\ Error, ${ARC_DUMP} not found. no import done"
else
  gzip -dc ${ARC_DUMP} | mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -P${MYSQL_HOST_PORT} -D ${MYSQL_DATABASE}
fi

if [[ ! -f ${ARC_FILE} ]]; then
  echo -e "\n/!\ Error, ${ARC_FILE} not found. no import done"
else
  tar -zxvf ${ARC_FILE}
fi

echo "OK: database backup and icinga configuration imported"