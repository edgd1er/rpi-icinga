#!/usr/bin/env bash
#
# create tables ofr nconf to operate
#

createDatabase(){
    echo creating database tables
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE  < /usr/share/icinga/create_database.sql
}


#generate mysql.php files with env values ( needed, because perl script get conf from php files, as i understood )
generateMysql(){
    echo settings credentials to acccess nconf database
cat > /var/www/html/nconf/config/mysql.php <<EOF
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

setRights(){
    echo setting rights for cache/icinga directory
    chown nagios:nagios /var/cache/icinga/
    chmod 777 /var/cache/icinga/.
    chmod 744 /var/cache/icinga/

}

waitForMysql() {
  n=0
  while (true and ${n} -lt 30 ); do
    /usr/bin/mysql -h ${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -P${MYSQL_HOST_PORT} -e 'show databases;'
    ret=$?
    [[ 0 == ${ret} ]] && echo -e "\n OK, DB is up and running \n" && break
    echo -e "\n Error, server ${MYSQL_HOST}:${MYSQL_HOST_PORT} is not up or db ${MYSQL_DATABASE} is not accessible with credentials ${MYSQL_USER} / ${MYSQL_PASSWORD}"
    sleep 5
    n++;
  done
}

## Main
# wait for mysql to be ready.
waitForMysql

res=$(mysql -h ${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -P${MYSQL_HOST_PORT} -Be 'show tables;')
ret=$?

if [ $ret -ne 0 -o $(echo $res | wc -w) -lt 7 ]; then
    echo -e "\n/!\Schema is not complete/!\ "
    createDatabase
    generateMysql
fi
setRights

echo -e "Starting apache"
supervisorctl start apache2
echo -e "Starting icinga"
supervisorctl start icinga