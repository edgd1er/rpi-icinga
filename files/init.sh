#!/usr/bin/env bash
#
# create tables ofr nconf to operate
#

ISMYSQL=0
HTUSER=${HTUSER:-icingaadmin}
HTPASS=${HTUSER:-icingaadmin}

createDatabase() {
  echo creating database tables
  mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE </usr/share/icinga/create_database.sql
}

#generate mysql.php files with env values ( needed, because perl script get conf from php files, as i understood )
generateMysql() {
  echo settings credentials to acccess nconf database
  cat >/var/www/html/nconf/config/mysql.php <<EOF
<?php
##
## MySQL config
##

#
# Main MySQL connection parameters
#
define('DBHOST', "$MYSQL_HOST");
define('DBNAME', "$MYSQL_DATABASE");
define('DBUSER', "$MYSQL_USER");
define('DBPASS', "$MYSQL_PASSWORD");

?>
EOF
}

#needed when /var/cache is mounted in memory
setRights() {
  echo "setting rights for cache/icinga directory"
  [[ ! -d /var/cache/icinga/ ]] && mkdir -p /var/cache/icinga/
  chown nagios:nagios /var/cache/icinga/
  chmod 755 /var/cache/icinga/.
  find /var/cache/icinga -type f -exec chmod 640 {} \;
}

waitForMysql() {
  n=0
  while (true and ${n} -lt 30); do
    /usr/bin/mysql -h ${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -P${MYSQL_HOST_PORT} -e 'show databases;'
    ret=$?
    [[ 0 == ${ret} ]] && echo -e "\n OK, DB is up and running \n" && ISMYSQL=1 && break
    echo -e "\n Error, server ${MYSQL_HOST}:${MYSQL_HOST_PORT} is not up or db ${MYSQL_DATABASE} is not accessible with credentials ${MYSQL_USER} / ${MYSQL_PASSWORD}"
    sleep 5
    n+=1
  done
}

setMailConfig() {
  cat >/etc/aliases <<EOF
# See man 5 aliases for format
# postmaster: root
postmaster: ${SMTP_FROM:-user@domain.tld}
root: ${SMTP_FROM:-user@domain.tld}
default: ${SMTP_FROM:-user@domain.tld}
EOF

  cat >/etc/msmtprc <<EOF
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log
aliases        /etc/aliases

#value are set through SMTP_{FROM,HOST,PORT,USER,PWD} env values
account icinga
host ${SMTP_HOST:-"domain.tld"}
port ${SMTP_PORT:-"007"}
from ${SMTP_FROM:-"user@domain.tld"}
tls on
tls_certcheck off
tls_starttls ${SMTP_STARTTLS:-off}
auth on
user ${SMTP_USER:-"user"}
password ${SMTP_PWD:-"password"}

# Set a default account
account default : icinga
EOF
}

setHtPasswd(){
  HTFILE=/etc/icinga/htpasswd.users
  [[ -w ${HTFILE} ]] && htpasswd -cb ${HTFILE} ${HTUSER} ${HTPASS} || echo
}

## Main
MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_HOST_PORT=${MYSQL_HOST_PORT:-3306}
# wait for mysql to be ready.
waitForMysql

[[ ${ISMYSQL} -eq 0 ]] && echo "Cannot connect to Mysql Database: ${MYSQL_HOST}:${MYSQL_HOST_PORT} , user ${MYSQL_USER}" && exit

res=$(mysql -h ${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -P${MYSQL_HOST_PORT} -Be 'show tables;')
ret=$?

if [ $ret -ne 0 -o $(echo $res | wc -w) -lt 7 ]; then
  echo -e "\n/!\Schema is not complete/!\ "
  createDatabase
fi

generateMysql
#needed when /var/cache is mounted
setMailConfig
sed -i.bak "s/LogLevel .*$/LogLevel debug/" /etc/apache2/apache2.conf

setRights
#define password at each restart
setHtPasswd

echo -e "Starting apache"
supervisorctl start apache2
echo -e "Starting icinga"
supervisorctl start icinga
supervisorctl start log
